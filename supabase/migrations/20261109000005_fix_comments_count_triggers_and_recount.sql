-- ==============================================================================
-- Migrasi Supabase: Fix Duplikasi Trigger Comments Count & Sinkronisasi Ulang
-- Sesuai Invarian AGENTS.md, menghapus duplikasi trigger dan menghitung COUNT(*) akurat
-- ==============================================================================

-- 1. Hapus trigger lama (baik versi singular 'trg_comment_count' maupun plural 'trg_comments_count')
--    untuk mencegah eksekusi ganda yang menyebabkan counter bernilai 2x lipat.
DROP TRIGGER IF EXISTS trg_comment_count ON public.comments;
DROP TRIGGER IF EXISTS trg_comments_count ON public.comments;

-- 2. Perbarui fungsi update_report_comments_count agar deterministik dan idempoten
--    menggunakan COUNT(*) langsung dari tabel public.comments (hanya yang belum dihapus/deleted_at IS NULL).
CREATE OR REPLACE FUNCTION public.update_report_comments_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_report_id TEXT;
    v_actual_count INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_report_id := OLD.report_id;
    ELSE
        v_report_id := NEW.report_id;
    END IF;

    IF v_report_id IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_actual_count
        FROM public.comments
        WHERE report_id = v_report_id
          AND deleted_at IS NULL;

        UPDATE public.reports
        SET comments_count = v_actual_count,
            updated_at = timezone('utc'::text, now())
        WHERE id = v_report_id;
    END IF;

    RETURN NULL;
END;
$$;

-- 3. Batasi hak eksekusi function internal
REVOKE EXECUTE ON FUNCTION public.update_report_comments_count() FROM PUBLIC, anon, authenticated;

-- 4. Pasang kembali satu trigger tunggal yang menangani INSERT, UPDATE (deleted_at), dan DELETE
CREATE TRIGGER trg_comments_count
    AFTER INSERT OR UPDATE OF deleted_at OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.update_report_comments_count();

-- 5. Perbaiki dan hitung ulang (backfill/recount) semua data laporan yang ada di public.reports
--    agar angka komentar yang sebelumnya terlipat ganda kembali sesuai dengan jumlah riil komentar.
UPDATE public.reports r
SET comments_count = COALESCE((
    SELECT COUNT(*)
    FROM public.comments c
    WHERE c.report_id = r.id
      AND c.deleted_at IS NULL
), 0);

