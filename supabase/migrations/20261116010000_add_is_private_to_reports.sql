-- ==============================================================================
-- Migrasi Supabase: Menambahkan Kolom is_private pada Tabel reports
-- Migration: 20261116010000_add_is_private_to_reports.sql
--
-- Tujuan:
-- 1. Menyimpan status privat laporan (is_private)
-- 2. Laporan privat tidak ditampilkan di feed publik warga
-- 3. Laporan privat menonaktifkan fitur komentar dan penilaian suara (vote)
-- ==============================================================================

BEGIN;

ALTER TABLE public.reports 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_reports_is_private ON public.reports(is_private);

-- Update get_national_feed RPC agar mengecualikan laporan privat secara native
CREATE OR REPLACE FUNCTION public.get_national_feed(
    p_cursor_created_at timestamp with time zone DEFAULT NULL::timestamp with time zone, 
    p_limit integer DEFAULT 20, 
    p_category text DEFAULT NULL::text, 
    p_status text DEFAULT NULL::text
)
RETURNS SETOF reports
LANGUAGE sql
STABLE
SET search_path TO 'public', 'pg_temp'
AS $function$
    SELECT r.*
    FROM public.reports r
    WHERE 
        r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.is_draft = FALSE
        AND r.is_private = FALSE
        AND r.publication_state = 'published'
        AND r.handling_status NOT IN ('rejected', 'cancelled')
        AND (p_cursor_created_at IS NULL OR r.created_at < p_cursor_created_at)
        AND (p_category IS NULL OR p_category = '' OR p_category = 'Semua' OR lower(r.category) = lower(p_category))
        AND (p_status IS NULL OR p_status = '' OR r.handling_status = p_status)
    ORDER BY r.created_at DESC
    LIMIT LEAST(p_limit, 50);
$function$;

-- Update RLS policy agar pembaca publik umum tidak dapat mengakses laporan privat
ALTER POLICY "Public can read active published reports" ON public.reports
USING (
    (
        deleted_at IS NULL 
        AND deleted_by_user = false 
        AND deleted_by_admin = false 
        AND is_draft = false 
        AND is_private = false
        AND publication_state = 'published'
        AND handling_status <> ALL (ARRAY['rejected'::text, 'cancelled'::text])
    )
    OR (
        (SELECT auth.uid() AS uid) IS NOT NULL 
        AND author_id = ((SELECT auth.uid() AS uid))::text 
        AND deleted_by_user = false
    )
    OR (
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = (SELECT auth.uid() AS uid) 
            AND p.role = 'admin'
        ) 
        AND deleted_by_admin = false
    )
);

COMMIT;
