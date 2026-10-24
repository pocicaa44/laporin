-- ==============================================================================
-- Migrasi Supabase: Kolom is_discussion_active pada Tabel Reports
-- Sesuai kebutuhan role USER: Toggle diskusi dan penutupan diskusi otomatis saat status SELESAI / DITOLAK
-- ==============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'is_discussion_active'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN is_discussion_active BOOLEAN NOT NULL DEFAULT true;
    END IF;
END $$;

-- Pastikan laporan yang sudah completed atau rejected diskusinya nonaktif secara default
UPDATE public.reports 
SET is_discussion_active = false 
WHERE handling_status IN ('completed', 'rejected');
