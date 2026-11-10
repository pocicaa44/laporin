-- ==============================================================================
-- LAPORIN BUSINESS RULES & INTEGRITY ENFORCEMENT
-- Migration: 20261110000000_report_immutability_and_admin_delete_rules.sql
-- 
-- 1. Task 1: Immutability Laporan (Status "Selesai" / "Ditolak")
--    - Mencegah modifikasi data laporan yang sudah berstatus 'completed' atau 'rejected'
--    - Memperbarui RLS UPDATE policy pada public.reports
--    - Menambahkan trigger BEFORE UPDATE untuk menolak edit konten laporan immutable
-- 
-- 2. Task 2: Aturan Penghapusan Laporan oleh Admin (Soft Delete Dependency)
--    - Admin HANYA dapat menghapus laporan jika pelapor (warga) telah menghapusnya (deleted_by_user = TRUE)
--    - Memperbarui RPC execute_dual_party_deletion dan RLS DELETE policy
-- 
-- 3. Task 3: Indeks & RPC Feed Admin Terfilter Provinsi
--    - Mengoptimalkan filtering data berdasarkan parameter provinsi pada feed admin
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. TASK 1: IMMUTABILITY LAPORAN BERSTATUS SELESAI / DITOLAK
-- ------------------------------------------------------------------------------

-- Perbarui RLS UPDATE pada public.reports:
-- Warga (author) hanya dapat mengupdate laporannya jika status BUKAN 'completed' atau 'rejected'
DROP POLICY IF EXISTS "Authors can update own reports" ON public.reports;
CREATE POLICY "Authors can update own reports"
ON public.reports FOR UPDATE
TO authenticated
USING (
    (
        author_id = (SELECT auth.uid())::text 
        AND deleted_by_user = FALSE
        AND handling_status NOT IN ('completed', 'rejected')
    )
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
)
WITH CHECK (
    (
        author_id = (SELECT auth.uid())::text 
        AND deleted_by_user = FALSE
        AND handling_status NOT IN ('completed', 'rejected')
    )
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- Trigger Function: Enforce Report Content Immutability
CREATE OR REPLACE FUNCTION public.validate_report_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_is_admin BOOLEAN := FALSE;
BEGIN
    -- Jika status lama adalah completed atau rejected
    IF OLD.handling_status IN ('completed', 'rejected') THEN
        SELECT (role = 'admin') INTO v_is_admin
        FROM public.profiles
        WHERE id = (SELECT auth.uid());

        -- Warga tidak diizinkan mengubah field konten laporan yang sudah selesai / ditolak
        IF NOT COALESCE(v_is_admin, FALSE) THEN
            IF NEW.title IS DISTINCT FROM OLD.title OR
               NEW.description IS DISTINCT FROM OLD.description OR
               NEW.category IS DISTINCT FROM OLD.category OR
               NEW.photo_urls IS DISTINCT FROM OLD.photo_urls OR
               NEW.location_address IS DISTINCT FROM OLD.location_address OR
               NEW.latitude IS DISTINCT FROM OLD.latitude OR
               NEW.longitude IS DISTINCT FROM OLD.longitude THEN
                RAISE EXCEPTION 'Akses ditolak: Laporan dengan status % bersifat permanen dan tidak dapat diedit.', OLD.handling_status
                    USING ERRCODE = '42501';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_report_immutability ON public.reports;
CREATE TRIGGER trg_enforce_report_immutability
BEFORE UPDATE ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.validate_report_immutability();


-- ------------------------------------------------------------------------------
-- 2. TASK 2: ATURAN PENGHAPUSAN LAPORAN OLEH ADMIN (SOFT DELETE DEPENDENCY)
-- ------------------------------------------------------------------------------

-- Perbarui RPC execute_dual_party_deletion:
-- Admin WAJIB memastikan pelapor telah menghapus laporannya terlebih dahulu (v_deleted_user = TRUE)
CREATE OR REPLACE FUNCTION public.execute_dual_party_deletion(
    p_report_id TEXT,
    p_is_admin BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID;
    v_is_real_admin BOOLEAN;
    v_author_id TEXT;
    v_deleted_user BOOLEAN;
    v_deleted_admin BOOLEAN;
    v_status TEXT;
    v_is_permanently_deleted BOOLEAN := FALSE;
BEGIN
    v_caller_id := (SELECT auth.uid());
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan untuk menghapus laporan.';
    END IF;

    SELECT (role = 'admin') INTO v_is_real_admin
    FROM public.profiles
    WHERE id = v_caller_id;

    SELECT author_id, deleted_by_user, deleted_by_admin, handling_status
    INTO v_author_id, v_deleted_user, v_deleted_admin, v_status
    FROM public.reports
    WHERE id = p_report_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Laporan tidak ditemukan.';
    END IF;

    -- Validasi hak penghapusan
    IF p_is_admin THEN
        IF NOT COALESCE(v_is_real_admin, false) THEN
            RAISE EXCEPTION 'Akses ditolak: hanya petugas/admin yang dapat melakukan aksi ini.';
        END IF;

        -- Aturan Bisnis: Admin HANYA dapat menghapus jika pelapor sudah menghapus laporan terlebih dahulu
        IF NOT COALESCE(v_deleted_user, false) THEN
            RAISE EXCEPTION 'Akses ditolak: Admin hanya dapat menghapus laporan yang sudah dihapus oleh pelapor terlebih dahulu.';
        END IF;

        v_deleted_admin := TRUE;
    ELSE
        IF v_author_id != v_caller_id::text THEN
            RAISE EXCEPTION 'Akses ditolak: Anda bukan pemilik laporan ini.';
        END IF;
        v_deleted_user := TRUE;
    END IF;

    -- Cek apakah kedua belah pihak sudah mengonfirmasi penghapusan (Hard Delete Fisik)
    IF v_deleted_user = TRUE AND v_deleted_admin = TRUE THEN
        DELETE FROM public.reports WHERE id = p_report_id;
        v_is_permanently_deleted := TRUE;
    ELSE
        UPDATE public.reports
        SET 
            deleted_by_user = v_deleted_user,
            deleted_by_user_at = CASE WHEN v_deleted_user AND deleted_by_user_at IS NULL THEN now() ELSE deleted_by_user_at END,
            deleted_by_admin = v_deleted_admin,
            deleted_by_admin_at = CASE WHEN v_deleted_admin AND deleted_by_admin_at IS NULL THEN now() ELSE deleted_by_admin_at END,
            deleted_at = COALESCE(deleted_at, now()),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_report_id;
    END IF;

    RETURN jsonb_build_object(
        'report_id', p_report_id,
        'deleted_by_user', v_deleted_user,
        'deleted_by_admin', v_deleted_admin,
        'is_permanently_deleted', v_is_permanently_deleted
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.execute_dual_party_deletion(TEXT, BOOLEAN) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.execute_dual_party_deletion(TEXT, BOOLEAN) FROM anon;

-- Perbarui RLS Policy DELETE pada public.reports:
-- Admin hanya dapat menghapus secara fisik jika pelapor telah menghapus (deleted_by_user = TRUE)
DROP POLICY IF EXISTS "Allow permanent delete when both user and admin deleted" ON public.reports;
CREATE POLICY "Allow permanent delete when both user and admin deleted"
ON public.reports FOR DELETE
TO authenticated
USING (
    (deleted_by_user = TRUE AND deleted_by_admin = TRUE)
    OR (
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
        ) AND deleted_by_user = TRUE
    )
    OR (
        (SELECT auth.uid()) IS NOT NULL 
        AND author_id = (SELECT auth.uid())::text 
        AND deleted_by_admin = TRUE
    )
);


-- ------------------------------------------------------------------------------
-- 3. TASK 3: FILTER WILAYAH PROVINSI PADA FEED ADMIN & INDEKS PERFORMA
-- ------------------------------------------------------------------------------

-- Pastikan indeks komposit untuk optimasi query feed admin berdasarkan provinsi & tanggal
CREATE INDEX IF NOT EXISTS idx_reports_province_id ON public.reports(province_id);
CREATE INDEX IF NOT EXISTS idx_reports_admin_feed_prov ON public.reports(deleted_by_admin, province_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_admin_status_prov ON public.reports(deleted_by_admin, handling_status, province_id);

-- RPC: Get Admin Reports dengan dukungan filter Provinsi dan Paginasi
CREATE OR REPLACE FUNCTION public.get_admin_reports(
    p_province_id UUID DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS SETOF public.reports
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT r.*
    FROM public.reports r
    WHERE 
        r.deleted_by_admin = FALSE
        AND r.is_draft = FALSE
        AND (p_province_id IS NULL OR r.province_id = p_province_id)
        AND (
            p_status IS NULL 
            OR p_status = '' 
            OR p_status = 'all'
            OR (p_status = 'deleted_by_user' AND r.deleted_by_user = TRUE)
            OR (p_status = 'held' AND r.publication_state = 'held')
            OR (p_status = 'new' AND r.handling_status = 'new')
            OR (p_status = 'in_progress' AND r.handling_status IN ('in_progress', 'accepted'))
            OR (p_status = 'completed' AND r.handling_status = 'completed')
            OR (p_status = 'rejected' AND r.handling_status = 'rejected')
            OR r.handling_status = p_status
        )
    ORDER BY r.created_at DESC
    LIMIT LEAST(p_limit, 100)
    OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.get_admin_reports(UUID, TEXT, INT, INT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_admin_reports(UUID, TEXT, INT, INT) FROM anon;

COMMIT;

