-- ==============================================================================
-- Migrasi Supabase: Menambahkan kolom is_draft pada tabel reports
-- Sesuai kebutuhan fitur penyimpanan draft laporan oleh warga
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'is_draft'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN is_draft BOOLEAN NOT NULL DEFAULT false;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reports_author_draft ON public.reports(author_id, is_draft);

-- Perbarui policy SELECT agar laporan draft hanya dapat dibaca oleh pemiliknya (author)
DROP POLICY IF EXISTS "Public can read active published reports" ON public.reports;
CREATE POLICY "Public can read active published reports"
ON public.reports FOR SELECT
TO authenticated, anon
USING (
    (
        deleted_at IS NULL
        AND publication_state = 'published'
        AND handling_status NOT IN ('rejected', 'cancelled')
        AND (is_draft IS FALSE OR is_draft IS NULL)
    )
    OR (auth.uid() IS NOT NULL AND author_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);
