-- ==============================================================================
-- Migrasi Supabase: Tabel In-App Notifications & Update Trigger Notifikasi
-- Sesuai PRD.md Bagian 10, FR-09, AGENTS.md & Halaman NotificationsScreen
-- ==============================================================================

-- 1. Buat Tabel public.notifications untuk Inbox Notifikasi In-App Pengguna
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'status_changed',
    report_id TEXT REFERENCES public.reports(id) ON DELETE CASCADE,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks performa query notifikasi pengguna
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy SELECT: Pengguna hanya dapat membaca notifikasi miliknya sendiri
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy UPDATE: Pengguna hanya dapat menandai dibaca notifikasi miliknya sendiri
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy DELETE: Pengguna hanya dapat menghapus notifikasi miliknya sendiri
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications"
ON public.notifications FOR DELETE
TO authenticated
USING (user_id = auth.uid());


-- 2. Perbarui Trigger Perubahan Status Laporan (Reports)
CREATE OR REPLACE FUNCTION public.trg_report_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status_label TEXT;
    v_msg TEXT;
    v_report_num TEXT;
BEGIN
    IF OLD.handling_status IS DISTINCT FROM NEW.handling_status 
       AND (NEW.is_draft IS NOT TRUE)
       AND NEW.deleted_at IS NULL THEN
        
        -- Insert ke antrean FCM
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'report_status_changed',
            jsonb_build_object(
                'report_id', NEW.id,
                'report_number', NEW.report_number,
                'author_id', NEW.author_id,
                'title', NEW.title,
                'old_status', OLD.handling_status,
                'new_status', NEW.handling_status,
                'rejection_reason', NEW.rejection_reason
            )
        );

        -- Tentukan label status & pesan yang ramah pengguna
        v_report_num := COALESCE(NEW.report_number, substring(NEW.id::text from 1 for 8));
        CASE NEW.handling_status
            WHEN 'accepted' THEN 
                v_status_label := 'Diterima';
                v_msg := 'Laporan #' || v_report_num || ' telah diverifikasi dan diterima oleh admin.';
            WHEN 'in_progress' THEN 
                v_status_label := 'Diproses';
                v_msg := 'Laporan #' || v_report_num || ' sedang dalam penanganan petugas.';
            WHEN 'completed' THEN 
                v_status_label := 'Selesai';
                v_msg := 'Laporan #' || v_report_num || ' telah selesai ditangani.';
            WHEN 'rejected' THEN 
                v_status_label := 'Ditolak';
                v_msg := 'Laporan #' || v_report_num || ' ditolak: ' || COALESCE(NEW.rejection_reason, 'Tidak memenuhi syarat.');
            WHEN 'cancelled' THEN 
                v_status_label := 'Dibatalkan';
                v_msg := 'Laporan #' || v_report_num || ' telah dibatalkan.';
            ELSE 
                v_status_label := NEW.handling_status;
                v_msg := 'Status laporan #' || v_report_num || ' diperbarui menjadi ' || NEW.handling_status || '.';
        END CASE;

        -- Insert ke inbox in-app notifications milik author laporan
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        VALUES (
            NEW.author_id,
            'Status Laporan: ' || v_status_label,
            v_msg,
            'status_changed',
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$;


-- 3. Perbarui Trigger Pengumuman Resmi (Announcements)
CREATE OR REPLACE FUNCTION public.trg_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_published = true AND (TG_OP = 'INSERT' OR OLD.is_published = false) THEN
        -- Insert ke antrean FCM
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'announcement_published',
            jsonb_build_object(
                'announcement_id', NEW.id,
                'title', NEW.title,
                'category', NEW.category,
                'author_id', NEW.author_id,
                'author_name', NEW.author_name,
                'content_preview', substring(NEW.content from 1 for 120)
            )
        );

        -- Broadcast salinan notifikasi in-app ke inbox semua pengguna
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        SELECT 
            p.id,
            'Pengumuman: ' || NEW.title,
            substring(NEW.content from 1 for 120),
            'announcement',
            NULL
        FROM public.profiles p;
    END IF;
    RETURN NEW;
END;
$$;
