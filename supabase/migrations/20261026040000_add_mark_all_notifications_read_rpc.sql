-- ==============================================================================
-- Migrasi Supabase: Fungsi RPC mark_all_notifications_read
-- Mengoptimalkan proses "Tandai Semua Dibaca" secara atomik di sisi database
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = true
    WHERE user_id = auth.uid() AND is_read = false;
END;
$$;

-- Berikan izin eksekusi ke pengguna terautentikasi
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;
