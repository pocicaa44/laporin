-- Migration: Menambahkan kolom completion_notes pada tabel reports
-- untuk menyimpan catatan/uraian penyelesaian pekerjaan oleh petugas admin

ALTER TABLE public.reports 
ADD COLUMN IF NOT EXISTS completion_notes text;

COMMENT ON COLUMN public.reports.completion_notes IS 'Catatan atau uraian hasil penanganan/penyelesaian pekerjaan oleh admin';
