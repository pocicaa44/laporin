-- ==============================================================================
-- Migrasi Supabase: Skema Penghapusan Laporan Dua Belah Pihak (Dual-Party Report Deletion)
-- Syarat Menghapus Permanen: Admin DAN User (Pelapor) harus sudah menghapus laporannya.
-- Jika kedua belah pihak sudah menghapus, laporan dihapus secara permanen dari database
-- dan seluruh media lampiran dibersihkan dari Supabase Storage.
-- ==============================================================================

-- 1. Tambahkan kolom penghapusan per-pihak pada tabel reports
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'deleted_by_user'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN deleted_by_user BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'deleted_by_user_at'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN deleted_by_user_at TIMESTAMPTZ;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'deleted_by_admin'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN deleted_by_admin BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'deleted_by_admin_at'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN deleted_by_admin_at TIMESTAMPTZ;
    END IF;
END $$;

-- Indeks untuk filtering laporan per-pihak
CREATE INDEX IF NOT EXISTS idx_reports_deleted_by_user ON public.reports(author_id, deleted_by_user);
CREATE INDEX IF NOT EXISTS idx_reports_deleted_by_admin ON public.reports(deleted_by_admin);

-- 2. Perbarui Policy RLS SELECT pada public.reports
DROP POLICY IF EXISTS "Public can read active published reports" ON public.reports;
CREATE POLICY "Public can read active published reports"
ON public.reports FOR SELECT
TO authenticated, anon
USING (
    (
        -- Feed publik: tidak tampil jika dihapus oleh user ATAU admin ATAU deleted_at diisi
        deleted_at IS NULL
        AND deleted_by_user = FALSE
        AND deleted_by_admin = FALSE
        AND publication_state = 'published'
        AND handling_status NOT IN ('rejected', 'cancelled')
    )
    OR (
        -- Pemilik laporan hanya dapat membaca laporannya jika belum dihapus oleh dirinya sendiri
        auth.uid() IS NOT NULL 
        AND author_id = auth.uid()::text 
        AND deleted_by_user = FALSE
    )
    OR (
        -- Admin dapat membaca laporan yang belum dihapus oleh admin
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = auth.uid() AND p.role = 'admin'
        )
        AND deleted_by_admin = FALSE
    )
);

-- 3. Policy DELETE:
-- Izinkan Hard Delete secara fisik jika kedua pihak telah menghapus (deleted_by_user = true AND deleted_by_admin = true)
DROP POLICY IF EXISTS "Deny physical delete for clients" ON public.reports;
DROP POLICY IF EXISTS "Allow permanent delete when both user and admin deleted" ON public.reports;

CREATE POLICY "Allow permanent delete when both user and admin deleted"
ON public.reports FOR DELETE
TO authenticated
USING (
    (deleted_by_user = TRUE AND deleted_by_admin = TRUE)
    OR (
        -- Admin menghapus saat user sudah menghapus sebelumnya
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = auth.uid() AND p.role = 'admin'
        ) AND deleted_by_user = TRUE
    )
    OR (
        -- User menghapus saat admin sudah menghapus sebelumnya
        auth.uid() IS NOT NULL 
        AND author_id = auth.uid()::text 
        AND deleted_by_admin = TRUE
    )
);

-- 4. Fungsi RPC Database untuk menghapus laporan secara aman & atomik
CREATE OR REPLACE FUNCTION public.execute_dual_party_deletion(
    p_report_id TEXT,
    p_is_admin BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_report RECORD;
    v_new_deleted_by_user BOOLEAN;
    v_new_deleted_by_admin BOOLEAN;
    v_user_id TEXT := auth.uid()::text;
    v_is_user_admin BOOLEAN := FALSE;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Pengguna belum terautentikasi';
    END IF;

    -- Periksa role admin jika p_is_admin true
    IF p_is_admin THEN
        SELECT is_admin() INTO v_is_user_admin;

        IF NOT COALESCE(v_is_user_admin, FALSE) THEN
            RAISE EXCEPTION 'Akses ditolak: Hanya admin yang berwenang melakukan aksi ini';
        END IF;
    END IF;

    SELECT * INTO v_report FROM public.reports WHERE id = p_report_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Laporan tidak ditemukan';
    END IF;

    -- Validasi kepemilikan jika dipanggil oleh user biasa
    IF NOT p_is_admin AND v_report.author_id <> v_user_id THEN
        RAISE EXCEPTION 'Akses ditolak: Anda bukan pemilik laporan ini';
    END IF;

    -- ATURAN PENGHAPUSAN:
    -- Selain laporan yang dihapus oleh user, yang sudah selesai atau ditolak,
    -- dan laporan yang batal, baik admin ataupun user TIDAK BISA menghapus laporan.
    IF p_is_admin THEN
        IF NOT (
            v_report.deleted_by_user = TRUE
            OR v_report.handling_status IN ('completed', 'rejected', 'cancelled')
        ) THEN
            RAISE EXCEPTION 'Akses ditolak: Admin hanya dapat menghapus laporan yang sudah dihapus oleh pelapor, atau berstatus selesai, ditolak, dan dibatalkan';
        END IF;
    ELSE
        IF NOT (
            v_report.deleted_by_admin = TRUE
            OR v_report.handling_status IN ('completed', 'rejected', 'cancelled')
        ) THEN
            RAISE EXCEPTION 'Akses ditolak: Pelapor hanya dapat menghapus laporan yang berstatus selesai, ditolak, atau dibatalkan';
        END IF;
    END IF;

    v_new_deleted_by_user := v_report.deleted_by_user;
    v_new_deleted_by_admin := v_report.deleted_by_admin;

    IF p_is_admin THEN
        v_new_deleted_by_admin := TRUE;
    ELSE
        v_new_deleted_by_user := TRUE;
    END IF;

    -- KONDISI DUAL PARTY: Jika kedua belah pihak sudah menghapus, lakukan penghapusan fisik permanen
    IF v_new_deleted_by_user AND v_new_deleted_by_admin THEN
        DELETE FROM public.reports WHERE id = p_report_id;
        RETURN jsonb_build_object(
            'status', 'permanently_deleted',
            'report_id', p_report_id,
            'photo_urls', v_report.photo_urls,
            'completion_proof_url', v_report.completion_proof_url
        );
    ELSE
        -- Jika baru satu pihak, tandai soft delete pihak tersebut
        UPDATE public.reports
        SET deleted_by_user = v_new_deleted_by_user,
            deleted_by_user_at = CASE WHEN p_is_admin THEN deleted_by_user_at ELSE NOW() END,
            deleted_by_admin = v_new_deleted_by_admin,
            deleted_by_admin_at = CASE WHEN p_is_admin THEN NOW() ELSE deleted_by_admin_at END,
            deleted_at = COALESCE(deleted_at, NOW()),
            handling_status = CASE 
                WHEN handling_status IN ('completed', 'rejected') THEN handling_status 
                ELSE 'cancelled' 
            END,
            moderation_reason = CASE 
                WHEN p_is_admin THEN 'Dihapus oleh admin' 
                ELSE 'Dihapus oleh pelapor' 
            END,
            terminal_at = COALESCE(terminal_at, NOW()),
            archive_after = NOW() + INTERVAL '24 hours',
            updated_at = NOW()
        WHERE id = p_report_id;

        RETURN jsonb_build_object(
            'status', 'marked_deleted',
            'report_id', p_report_id,
            'deleted_by_user', v_new_deleted_by_user,
            'deleted_by_admin', v_new_deleted_by_admin
        );
    END IF;
END;
$$;
