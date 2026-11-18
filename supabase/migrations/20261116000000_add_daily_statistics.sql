-- ==============================================================================
-- Migrasi Supabase: RPC Function Statistik Harian Laporan (Laporan Masuk per Tanggal)
-- Migration: 20261116000000_add_daily_statistics.sql
--
-- Tujuan:
-- 1. Menyediakan RPC Function get_admin_daily_statistics untuk mengagregasi
--    laporan masuk per tanggal (harian) dari tabel reports dan report_statistics_archive
-- 2. Memastikan data historis tetap terekam meski laporan dihapus (dual-party deletion)
-- ==============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_admin_daily_statistics(
    p_period_year_month TEXT DEFAULT NULL,
    p_start_date TIMESTAMPTZ DEFAULT NULL,
    p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID;
    v_is_admin BOOLEAN := FALSE;
    v_daily_data JSONB;
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

    -- Agregasi laporan aktif dan terhapus historis per hari
    WITH all_records AS (
        SELECT 
            id::text AS id,
            created_at,
            handling_status,
            category,
            (deleted_by_user AND deleted_by_admin) AS is_deleted
        FROM public.reports
        WHERE (p_period_year_month IS NULL OR to_char(created_at, 'YYYY-MM') = p_period_year_month)
          AND (p_start_date IS NULL OR created_at >= p_start_date)
          AND (p_end_date IS NULL OR created_at <= p_end_date)
        
        UNION ALL

        SELECT 
            id,
            created_at,
            handling_status,
            category,
            is_deleted
        FROM public.report_statistics_archive
        WHERE (p_period_year_month IS NULL OR period_year_month = p_period_year_month)
          AND (p_start_date IS NULL OR created_at >= p_start_date)
          AND (p_end_date IS NULL OR created_at <= p_end_date)
          AND id NOT IN (SELECT id::text FROM public.reports)
    ),
    daily_grouped AS (
        SELECT 
            to_char(created_at, 'YYYY-MM-DD') AS date_string,
            date_trunc('day', created_at)::timestamptz AS period_date,
            COUNT(*) AS total_reports,
            COUNT(*) FILTER (WHERE handling_status = 'completed' AND NOT is_deleted) AS completed_reports,
            COUNT(*) FILTER (WHERE handling_status = 'rejected' AND NOT is_deleted) AS rejected_reports,
            COUNT(*) FILTER (WHERE handling_status IN ('accepted', 'inProgress') AND NOT is_deleted) AS in_progress_reports,
            COUNT(*) FILTER (WHERE handling_status = 'newReport' AND NOT is_deleted) AS new_reports,
            COUNT(*) FILTER (WHERE is_deleted OR handling_status = 'cancelled') AS deleted_reports
        FROM all_records
        GROUP BY 1, 2
        ORDER BY 2 ASC
    )
    SELECT COALESCE(jsonb_agg(to_jsonb(d)), '[]'::jsonb)
    INTO v_daily_data
    FROM daily_grouped d;

    RETURN v_daily_data;
END;
$$;

COMMIT;
