-- ==============================================================================
-- Migrasi Supabase: Tabel Device Tokens, Antrean Notifikasi, dan Trigger Notifikasi FCM
-- Sesuai PRD.md Bagian 10, FR-09, AGENTS.md & Integrasi FCM Android
-- ==============================================================================

-- 1. Tabel Device Tokens untuk menyimpan token FCM per pengguna
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL DEFAULT 'android',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeks performa pencarian token berdasarkan pengguna dan token
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON public.device_tokens(token);

-- Aktifkan Row Level Security (RLS) pada tabel device_tokens
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Policy SELECT: Pengguna hanya boleh membaca token milik sendiri
DROP POLICY IF EXISTS "Users can view their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can view their own device tokens"
ON public.device_tokens FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy INSERT: Pengguna hanya boleh mendaftarkan token untuk akunnya sendiri
DROP POLICY IF EXISTS "Users can insert their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can insert their own device tokens"
ON public.device_tokens FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy UPDATE: Pengguna hanya boleh memperbarui token miliknya
DROP POLICY IF EXISTS "Users can update their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can update their own device tokens"
ON public.device_tokens FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy DELETE: Pengguna hanya boleh menghapus token miliknya (saat logout)
DROP POLICY IF EXISTS "Users can delete their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can delete their own device tokens"
ON public.device_tokens FOR DELETE
TO authenticated
USING (user_id = auth.uid());


-- 2. Stored Procedures / RPC untuk Registrasi & Disasosiasi Token yang Aman

-- RPC: Upsert device token secara atomik menggunakan auth.uid() server-side
CREATE OR REPLACE FUNCTION public.upsert_device_token(
    p_token TEXT,
    p_platform TEXT DEFAULT 'android'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_token IS NULL OR trim(p_token) = '' THEN
        RETURN;
    END IF;

    -- Jika token sudah ada (misal di perangkat sama tapi ganti akun),
    -- alihkan asosiasi token ke pengguna baru secara atomik
    INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
    VALUES (v_user_id, trim(p_token), COALESCE(NULLIF(trim(p_platform), ''), 'android'), now())
    ON CONFLICT (token) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        updated_at = now();
END;
$$;

-- RPC: Hapus device token saat pengguna logout
CREATE OR REPLACE FUNCTION public.delete_device_token(
    p_token TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RETURN;
    END IF;

    DELETE FROM public.device_tokens
    WHERE token = trim(p_token)
      AND user_id = auth.uid();
END;
$$;


-- 3. Tabel Antrean Notifikasi (Notification Queue) untuk decoupling transaksi & audit log
CREATE TABLE IF NOT EXISTS public.notification_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL, -- 'report_status_changed' | 'announcement_published'
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'processed' | 'failed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ,
    error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_notification_queue_status ON public.notification_queue(status, created_at);

-- RLS: Hanya admin / server role yang dapat menginspeksi antrean
ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view notification queue" ON public.notification_queue;
CREATE POLICY "Admins can view notification queue"
ON public.notification_queue FOR SELECT
TO authenticated
USING (public.is_admin());


-- 4. Database Trigger untuk Event 1: Perubahan Status Penanganan Laporan (handling_status)
CREATE OR REPLACE FUNCTION public.trg_report_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Hanya jadwalkan notifikasi jika handling_status benar-benar berubah,
    -- bukan berupa draft, dan laporan belum dihapus (soft-delete)
    IF OLD.handling_status IS DISTINCT FROM NEW.handling_status 
       AND (NEW.is_draft IS NOT TRUE)
       AND NEW.deleted_at IS NULL THEN
        
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
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_status_notification ON public.reports;
CREATE TRIGGER trg_reports_status_notification
AFTER UPDATE OF handling_status ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.trg_report_status_notification();


-- 5. Database Trigger untuk Event 2: Pengumuman Baru yang Dipublikasikan
CREATE OR REPLACE FUNCTION public.trg_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Notifikasi dikirim saat pengumuman baru langsung dipublikasikan (INSERT),
    -- atau saat statusnya beralih dari draft ke published (UPDATE)
    IF NEW.is_published = true AND (TG_OP = 'INSERT' OR OLD.is_published = false) THEN
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
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_announcements_notification ON public.announcements;
CREATE TRIGGER trg_announcements_notification
AFTER INSERT OR UPDATE OF is_published ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.trg_announcement_notification();
