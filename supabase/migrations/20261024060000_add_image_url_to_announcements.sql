-- ==============================================================================
-- Migrasi Supabase: Tambah Kolom image_url pada Tabel announcements
-- ==============================================================================

ALTER TABLE public.announcements 
ADD COLUMN IF NOT EXISTS image_url TEXT;
