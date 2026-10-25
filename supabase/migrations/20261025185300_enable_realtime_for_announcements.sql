-- Migrasi Supabase: Aktifkan Supabase Realtime pada Tabel announcements
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER TABLE public.announcements REPLICA IDENTITY FULL;
