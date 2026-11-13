-- ==============================================================================
-- Migrasi Supabase: Modifikasi Backend untuk Retensi Statistik Laporan
-- Migration: 20261113000000_create_report_statistics_and_retention.sql
--
-- Tujuan:
-- 1. Menyimpan ringkasan statistik laporan per-bulan secara persisten (report_monthly_stats)
-- 2. Menyimpan arsip historis laporan (report_statistics_archive)
-- 3. Memastikan bahwa meskipun laporan dihapus secara fisik (hard delete / dual-party deletion),
--    data statistik jumlah laporan pada bulan tersebut TETAP BERFUNGSI dan TIDAK HILANG.
-- ==============================================================================

BEGIN;

-- 1. Tabel Agregat Statistik Bulanan
CREATE TABLE IF NOT EXISTS public.report_monthly_stats (
    period_year_month TEXT PRIMARY KEY, -- Format: 'YYYY-MM', misal '2026-11'
    year INT NOT NULL,                  -- 2026
    month INT NOT NULL,                 -- 11
    period_date DATE NOT NULL,          -- '2026-11-01'
    total_reports INT NOT NULL DEFAULT 0,
    completed_reports INT NOT NULL DEFAULT 0,
    rejected_reports INT NOT NULL DEFAULT 0,
    in_progress_reports INT NOT NULL DEFAULT 0,
    new_reports INT NOT NULL DEFAULT 0,
    deleted_reports INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Indeks untuk pencarian periode
CREATE INDEX IF NOT EXISTS idx_report_monthly_stats_date ON public.report_monthly_stats(period_date DESC);

-- 2. Tabel Agregat Statistik Kategori Bulanan
CREATE TABLE IF NOT EXISTS public.report_category_monthly_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    period_year_month TEXT NOT NULL,
    category TEXT NOT NULL,
    total_reports INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_period_category UNIQUE (period_year_month, category)
);

CREATE INDEX IF NOT EXISTS idx_report_category_monthly_stats_ym ON public.report_category_monthly_stats(period_year_month);

-- 3. Tabel Arsip Historis Statistik Laporan (Retensi Permanen setelah Hard Delete)
CREATE TABLE IF NOT EXISTS public.report_statistics_archive (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL,
    period_year_month TEXT NOT NULL,
    category TEXT NOT NULL,
    handling_status TEXT NOT NULL,
    area_id TEXT,
    area_name TEXT,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_report_stats_archive_ym ON public.report_statistics_archive(period_year_month);
CREATE INDEX IF NOT EXISTS idx_report_stats_archive_status ON public.report_statistics_archive(handling_status);

-- 4. Trigger Function: Catat Statistik saat Laporan Baru Dibuat (INSERT)
CREATE OR REPLACE FUNCTION public.record_report_statistics_on_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_ym TEXT;
    v_year INT;
    v_month INT;
    v_period_date DATE;
BEGIN
    v_ym := to_char(NEW.created_at, 'YYYY-MM');
    v_year := EXTRACT(YEAR FROM NEW.created_at)::int;
    v_month := EXTRACT(MONTH FROM NEW.created_at)::int;
    v_period_date := date_trunc('month', NEW.created_at)::date;

    -- 1. Upsert ke report_monthly_stats
    INSERT INTO public.report_monthly_stats (
        period_year_month,
        year,
        month,
        period_date,
        total_reports,
        new_reports,
        in_progress_reports,
        completed_reports,
        rejected_reports,
        deleted_reports,
        updated_at
    ) VALUES (
        v_ym,
        v_year,
        v_month,
        v_period_date,
        1,
        CASE WHEN NEW.handling_status = 'newReport' THEN 1 ELSE 0 END,
        CASE WHEN NEW.handling_status IN ('accepted', 'inProgress') THEN 1 ELSE 0 END,
        CASE WHEN NEW.handling_status = 'completed' THEN 1 ELSE 0 END,
        CASE WHEN NEW.handling_status = 'rejected' THEN 1 ELSE 0 END,
        0,
        timezone('utc'::text, now())
    )
    ON CONFLICT (period_year_month) DO UPDATE
    SET 
        total_reports = report_monthly_stats.total_reports + 1,
        new_reports = report_monthly_stats.new_reports + CASE WHEN NEW.handling_status = 'newReport' THEN 1 ELSE 0 END,
        in_progress_reports = report_monthly_stats.in_progress_reports + CASE WHEN NEW.handling_status IN ('accepted', 'inProgress') THEN 1 ELSE 0 END,
        completed_reports = report_monthly_stats.completed_reports + CASE WHEN NEW.handling_status = 'completed' THEN 1 ELSE 0 END,
        rejected_reports = report_monthly_stats.rejected_reports + CASE WHEN NEW.handling_status = 'rejected' THEN 1 ELSE 0 END,
        updated_at = timezone('utc'::text, now());

    -- 2. Upsert ke report_category_monthly_stats
    INSERT INTO public.report_category_monthly_stats (
        period_year_month,
        category,
        total_reports,
        updated_at
    ) VALUES (
        v_ym,
        COALESCE(NEW.category, 'Lainnya'),
        1,
        timezone('utc'::text, now())
    )
    ON CONFLICT (period_year_month, category) DO UPDATE
    SET 
        total_reports = report_category_monthly_stats.total_reports + 1,
        updated_at = timezone('utc'::text, now());

    -- 3. Simpan ke arsip historis permanen
    INSERT INTO public.report_statistics_archive (
        id,
        created_at,
        period_year_month,
        category,
        handling_status,
        area_id,
        area_name,
        is_deleted,
        deleted_at
    ) VALUES (
        NEW.id,
        NEW.created_at,
        v_ym,
        COALESCE(NEW.category, 'Lainnya'),
        NEW.handling_status,
        NEW.area_id,
        NEW.area_name,
        FALSE,
        NULL
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        category = EXCLUDED.category,
        handling_status = EXCLUDED.handling_status,
        area_id = EXCLUDED.area_id,
        area_name = EXCLUDED.area_name;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_record_report_stats_insert ON public.reports;
CREATE TRIGGER trg_record_report_stats_insert
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.record_report_statistics_on_insert();

-- 5. Trigger Function: Update Status Statistik saat Laporan Diperbarui (UPDATE)
CREATE OR REPLACE FUNCTION public.update_report_statistics_on_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_ym TEXT;
BEGIN
    v_ym := to_char(NEW.created_at, 'YYYY-MM');

    -- Jika handling_status berubah
    IF NEW.handling_status IS DISTINCT FROM OLD.handling_status THEN
        UPDATE public.report_statistics_archive
        SET handling_status = NEW.handling_status
        WHERE id = NEW.id;

        UPDATE public.report_monthly_stats
        SET 
            new_reports = GREATEST(0, new_reports + CASE 
                WHEN NEW.handling_status = 'newReport' THEN 1 
                WHEN OLD.handling_status = 'newReport' THEN -1 
                ELSE 0 END),
            in_progress_reports = GREATEST(0, in_progress_reports + CASE 
                WHEN NEW.handling_status IN ('accepted', 'inProgress') THEN 1 
                WHEN OLD.handling_status IN ('accepted', 'inProgress') THEN -1 
                ELSE 0 END),
            completed_reports = GREATEST(0, completed_reports + CASE 
                WHEN NEW.handling_status = 'completed' THEN 1 
                WHEN OLD.handling_status = 'completed' THEN -1 
                ELSE 0 END),
            rejected_reports = GREATEST(0, rejected_reports + CASE 
                WHEN NEW.handling_status = 'rejected' THEN 1 
                WHEN OLD.handling_status = 'rejected' THEN -1 
                ELSE 0 END),
            updated_at = timezone('utc'::text, now())
        WHERE period_year_month = v_ym;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_report_stats_update ON public.reports;
CREATE TRIGGER trg_update_report_stats_update
AFTER UPDATE ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.update_report_statistics_on_update();

-- 6. Trigger Function: Retensi Statistik saat Laporan Dihapus Fisik (BEFORE DELETE)
-- PENTING: Memastikan statistik dan arsip bulan laporan TETAP UTUH meskipun baris fisik dihapus!
CREATE OR REPLACE FUNCTION public.retain_report_statistics_on_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_ym TEXT;
BEGIN
    v_ym := to_char(OLD.created_at, 'YYYY-MM');

    -- Tandai pada tabel arsip bahwa laporan ini sudah dihapus fisik, tapi riwayat bulan & kategorinya tetap ada
    UPDATE public.report_statistics_archive
    SET 
        is_deleted = TRUE,
        deleted_at = timezone('utc'::text, now())
    WHERE id = OLD.id;

    -- Pada report_monthly_stats: total_reports TIDAK DIKURANGI!
    -- Hanya deleted_reports yang ditambahkan agar histori total laporan bulan tsb tetap valid.
    UPDATE public.report_monthly_stats
    SET 
        deleted_reports = deleted_reports + 1,
        new_reports = GREATEST(0, new_reports - CASE WHEN OLD.handling_status = 'newReport' THEN 1 ELSE 0 END),
        in_progress_reports = GREATEST(0, in_progress_reports - CASE WHEN OLD.handling_status IN ('accepted', 'inProgress') THEN 1 ELSE 0 END),
        updated_at = timezone('utc'::text, now())
    WHERE period_year_month = v_ym;

    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_retain_report_stats_delete ON public.reports;
CREATE TRIGGER trg_retain_report_stats_delete
BEFORE DELETE ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.retain_report_statistics_on_delete();

-- 7. Backfill Data Existing dari public.reports
INSERT INTO public.report_statistics_archive (
    id,
    created_at,
    period_year_month,
    category,
    handling_status,
    area_id,
    area_name,
    is_deleted,
    deleted_at
)
SELECT 
    r.id,
    r.created_at,
    to_char(r.created_at, 'YYYY-MM'),
    COALESCE(r.category, 'Lainnya'),
    r.handling_status,
    r.area_id,
    r.area_name,
    COALESCE(r.deleted_by_user AND r.deleted_by_admin, FALSE),
    r.deleted_at
FROM public.reports r
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.report_monthly_stats (
    period_year_month,
    year,
    month,
    period_date,
    total_reports,
    completed_reports,
    rejected_reports,
    in_progress_reports,
    new_reports,
    deleted_reports,
    updated_at
)
SELECT 
    to_char(r.created_at, 'YYYY-MM') AS period_year_month,
    EXTRACT(YEAR FROM r.created_at)::int AS year,
    EXTRACT(MONTH FROM r.created_at)::int AS month,
    date_trunc('month', r.created_at)::date AS period_date,
    count(*) AS total_reports,
    count(*) FILTER (WHERE r.handling_status = 'completed') AS completed_reports,
    count(*) FILTER (WHERE r.handling_status = 'rejected') AS rejected_reports,
    count(*) FILTER (WHERE r.handling_status IN ('accepted', 'inProgress')) AS in_progress_reports,
    count(*) FILTER (WHERE r.handling_status = 'newReport') AS new_reports,
    count(*) FILTER (WHERE r.deleted_by_user = TRUE OR r.deleted_by_admin = TRUE) AS deleted_reports,
    timezone('utc'::text, now())
FROM public.reports r
GROUP BY to_char(r.created_at, 'YYYY-MM'), EXTRACT(YEAR FROM r.created_at)::int, EXTRACT(MONTH FROM r.created_at)::int, date_trunc('month', r.created_at)::date
ON CONFLICT (period_year_month) DO UPDATE
SET 
    total_reports = EXCLUDED.total_reports,
    completed_reports = EXCLUDED.completed_reports,
    rejected_reports = EXCLUDED.rejected_reports,
    in_progress_reports = EXCLUDED.in_progress_reports,
    new_reports = EXCLUDED.new_reports,
    deleted_reports = EXCLUDED.deleted_reports,
    updated_at = timezone('utc'::text, now());

INSERT INTO public.report_category_monthly_stats (
    period_year_month,
    category,
    total_reports,
    updated_at
)
SELECT 
    to_char(r.created_at, 'YYYY-MM') AS period_year_month,
    COALESCE(r.category, 'Lainnya') AS category,
    count(*) AS total_reports,
    timezone('utc'::text, now())
FROM public.reports r
GROUP BY to_char(r.created_at, 'YYYY-MM'), COALESCE(r.category, 'Lainnya')
ON CONFLICT (period_year_month, category) DO UPDATE
SET 
    total_reports = EXCLUDED.total_reports,
    updated_at = timezone('utc'::text, now());

-- 8. RLS Security Policies
ALTER TABLE public.report_monthly_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_category_monthly_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_statistics_archive ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view monthly report stats" ON public.report_monthly_stats;
CREATE POLICY "Admins can view monthly report stats"
ON public.report_monthly_stats FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Admins can view category monthly stats" ON public.report_category_monthly_stats;
CREATE POLICY "Admins can view category monthly stats"
ON public.report_category_monthly_stats FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Admins can view report statistics archive" ON public.report_statistics_archive;
CREATE POLICY "Admins can view report statistics archive"
ON public.report_statistics_archive FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- 9. RPC Function untuk Membaca Statistik Bulanan Secara Terstruktur
CREATE OR REPLACE FUNCTION public.get_admin_monthly_statistics(
    p_period_year_month TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID;
    v_is_admin BOOLEAN := FALSE;
    v_monthly_data JSONB;
    v_categories_data JSONB;
BEGIN
    v_caller_id := (SELECT auth.uid());
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Akses ditolak: Autentikasi diperlukan.';
    END IF;

    SELECT (role = 'admin') INTO v_is_admin
    FROM public.profiles
    WHERE id = v_caller_id;

    IF NOT COALESCE(v_is_admin, FALSE) THEN
        RAISE EXCEPTION 'Akses ditolak: Hanya admin/petugas yang dapat mengakses data statistik.';
    END IF;

    -- Ambil data statistik bulanan
    SELECT COALESCE(jsonb_agg(to_jsonb(s) ORDER BY s.period_date DESC), '[]'::jsonb)
    INTO v_monthly_data
    FROM public.report_monthly_stats s
    WHERE (p_period_year_month IS NULL OR s.period_year_month = p_period_year_month);

    -- Ambil rincian kategori
    SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY c.total_reports DESC), '[]'::jsonb)
    INTO v_categories_data
    FROM public.report_category_monthly_stats c
    WHERE (p_period_year_month IS NULL OR c.period_year_month = p_period_year_month);

    RETURN jsonb_build_object(
        'monthly_stats', v_monthly_data,
        'category_stats', v_categories_data
    );
END;
$$;

COMMIT;

