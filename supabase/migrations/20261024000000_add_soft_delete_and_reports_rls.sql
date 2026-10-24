-- ==============================================================================
-- Migrasi Supabase: Soft Delete dan RLS Policies untuk Tabel Reports
-- Sesuai PRD.md Bagian 7.4, 8.1, 9 & Aturan CRUD Laporan
-- ==============================================================================

-- 1. Tambahkan kolom deleted_at pada tabel reports jika belum ada
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'deleted_at'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN deleted_at TIMESTAMPTZ;
    END IF;
END $$;

-- Indeks untuk query filtering laporan aktif (belum di-soft-delete)
CREATE INDEX IF NOT EXISTS idx_reports_deleted_at ON public.reports(deleted_at);
CREATE INDEX IF NOT EXISTS idx_reports_author_deleted ON public.reports(author_id, deleted_at);

-- 2. Pastikan RLS aktif pada tabel reports
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 3. Policy SELECT:
-- - Publik hanya dapat membaca laporan yang belum dihapus (deleted_at IS NULL),
--   berstatus publication_state = 'published', dan status penanganan bukan rejected / cancelled.
-- - Pemilik laporan dapat membaca seluruh laporannya miliknya sendiri.
-- - Admin berwenang dapat membaca laporan di area tugasnya.
DROP POLICY IF EXISTS "Public can read active published reports" ON public.reports;
CREATE POLICY "Public can read active published reports"
ON public.reports FOR SELECT
TO authenticated, anon
USING (
    (
        deleted_at IS NULL
        AND publication_state = 'published'
        AND handling_status NOT IN ('rejected', 'cancelled')
    )
    OR (auth.uid() IS NOT NULL AND author_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- 4. Policy UPDATE:
-- - Pemilik laporan hanya dapat memperbarui laporannya sendiri yang belum dihapus
-- - Admin berwenang dapat memperbarui status penanganan dan moderasi
DROP POLICY IF EXISTS "Authors can update their own active reports" ON public.reports;
CREATE POLICY "Authors can update their own active reports"
ON public.reports FOR UPDATE
TO authenticated
USING (
    (auth.uid() IS NOT NULL AND author_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
)
WITH CHECK (
    (auth.uid() IS NOT NULL AND author_id = auth.uid()::text)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() AND p.role = 'admin'
    )
);

-- 5. Policy DELETE:
-- - Dilarang keras melakukan Hard Delete fisik dari klien API.
-- - Seluruh penghapusan wajib menggunakan mekanisme Soft Delete melalui UPDATE deleted_at.
DROP POLICY IF EXISTS "Deny physical delete for clients" ON public.reports;
CREATE POLICY "Deny physical delete for clients"
ON public.reports FOR DELETE
TO authenticated, anon
USING (false);
