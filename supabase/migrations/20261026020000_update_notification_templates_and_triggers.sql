-- ==============================================================================
-- Migrasi Supabase: Standardisasi Template Notifikasi (User & Admin) & Triggers
-- Sesuai Format Copywriting Laporin
-- ==============================================================================

-- 1. Helper Function: Konversi handling_status ke label bahasa Indonesia
CREATE OR REPLACE FUNCTION public.format_handling_status_label(p_status TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT CASE p_status
        WHEN 'accepted' THEN 'diterima'
        WHEN 'in_progress' THEN 'diproses'
        WHEN 'completed' THEN 'selesai'
        WHEN 'rejected' THEN 'ditolak'
        WHEN 'cancelled' THEN 'dibatalkan'
        WHEN 'new' THEN 'baru'
        ELSE p_status
    END;
$$;


-- 2. Trigger Event 1: Perubahan Status Laporan (User)
-- header = Status Laporan Diperbarui!
-- child  = laporan {judul laporan} {status}
CREATE OR REPLACE FUNCTION public.trg_report_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status_label TEXT;
    v_header TEXT;
    v_child TEXT;
BEGIN
    IF OLD.handling_status IS DISTINCT FROM NEW.handling_status 
       AND (NEW.is_draft IS NOT TRUE)
       AND NEW.deleted_at IS NULL THEN
        
        v_status_label := public.format_handling_status_label(NEW.handling_status);
        v_header := 'Status Laporan Diperbarui!';
        v_child := 'laporan ' || NEW.title || ' ' || v_status_label;

        -- 1. Insert ke inbox in-app notifications pemilik laporan
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        VALUES (
            NEW.author_id,
            v_header,
            v_child,
            'status_changed',
            NEW.id
        );

        -- 2. Insert ke antrean push notification FCM
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'report_status_changed',
            jsonb_build_object(
                'title', v_header,
                'body', v_child,
                'recipient_user_ids', jsonb_build_array(NEW.author_id),
                'report_id', NEW.id,
                'data', jsonb_build_object(
                    'type', 'report_status_changed',
                    'report_id', NEW.id,
                    'handling_status', NEW.handling_status
                )
            )
        );
    END IF;
    RETURN NEW;
END;
$$;


-- 3. Trigger Event 2: Komentar Baru & Balasan Komentar (User)
-- Komentar baru:
--   header = Seseorang Mengomentari Laporan Anda!
--   child  = ketuk untuk melihat.
-- Balas komentar:
--   header = Seseorang Membalas Komentar Anda!
--   child  = ketuk untuk melihat
CREATE OR REPLACE FUNCTION public.trg_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_target_user_id UUID;
    v_header TEXT;
    v_child TEXT;
    v_event_type TEXT;
    v_notif_type TEXT;
    v_parent_author_text TEXT;
    v_report_author_text TEXT;
BEGIN
    -- Abaikan jika komentar sudah ditandai terhapus (soft-delete)
    IF NEW.deleted_at IS NOT NULL THEN
        RETURN NEW;
    END IF;

    IF NEW.parent_comment_id IS NOT NULL THEN
        -- Balasan Komentar
        SELECT author_id INTO v_parent_author_text
        FROM public.comments
        WHERE id = NEW.parent_comment_id;

        -- Hanya kirim jika yang membalas bukan pembuat komentar itu sendiri
        IF v_parent_author_text IS NOT NULL AND v_parent_author_text <> NEW.author_id THEN
            BEGIN
                v_target_user_id := v_parent_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_header := 'Seseorang Membalas Komentar Anda!';
                v_child := 'ketuk untuk melihat';
                v_event_type := 'reply_comment';
                v_notif_type := 'reply_comment';

                -- Simpan ke in-app inbox
                INSERT INTO public.notifications (user_id, title, message, type, report_id)
                VALUES (v_target_user_id, v_header, v_child, v_notif_type, NEW.report_id);

                -- Enqueue ke FCM
                INSERT INTO public.notification_queue (event_type, payload)
                VALUES (
                    v_event_type,
                    jsonb_build_object(
                        'title', v_header,
                        'body', v_child,
                        'recipient_user_ids', jsonb_build_array(v_parent_author_text),
                        'report_id', NEW.report_id,
                        'data', jsonb_build_object(
                            'type', 'reply_comment',
                            'report_id', NEW.report_id,
                            'comment_id', NEW.id
                        )
                    )
                );
            END IF;
        END IF;
    ELSE
        -- Komentar Baru pada Laporan
        SELECT author_id INTO v_report_author_text
        FROM public.reports
        WHERE id = NEW.report_id;

        -- Hanya kirim jika pengomentar bukan pemilik laporan itu sendiri
        IF v_report_author_text IS NOT NULL AND v_report_author_text <> NEW.author_id THEN
            BEGIN
                v_target_user_id := v_report_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_header := 'Seseorang Mengomentari Laporan Anda!';
                v_child := 'ketuk untuk melihat.';
                v_event_type := 'new_comment';
                v_notif_type := 'new_comment';

                -- Simpan ke in-app inbox
                INSERT INTO public.notifications (user_id, title, message, type, report_id)
                VALUES (v_target_user_id, v_header, v_child, v_notif_type, NEW.report_id);

                -- Enqueue ke FCM
                INSERT INTO public.notification_queue (event_type, payload)
                VALUES (
                    v_event_type,
                    jsonb_build_object(
                        'title', v_header,
                        'body', v_child,
                        'recipient_user_ids', jsonb_build_array(v_report_author_text),
                        'report_id', NEW.report_id,
                        'data', jsonb_build_object(
                            'type', 'new_comment',
                            'report_id', NEW.report_id,
                            'comment_id', NEW.id
                        )
                    )
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_notification ON public.comments;
CREATE TRIGGER trg_comments_notification
AFTER INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.trg_comment_notification();


-- 4. Trigger Event 3: Dukungan / Upvote Baru (User)
-- header = Laporan Anda Mendapat Dukungan!
-- child  = laporan {judul laporan} mendapat dukungan. ketuk untuk melihat
CREATE OR REPLACE FUNCTION public.trg_vote_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_report_author_text TEXT;
    v_report_title TEXT;
    v_target_user_id UUID;
    v_header TEXT;
    v_child TEXT;
BEGIN
    -- Hanya kirim jika vote_type adalah 'up'
    IF NEW.vote_type = 'up' AND (TG_OP = 'INSERT' OR OLD.vote_type <> 'up') THEN
        SELECT author_id, title INTO v_report_author_text, v_report_title
        FROM public.reports
        WHERE id = NEW.report_id;

        -- Hanya kirim jika yang memberi upvote bukan pemilik laporan itu sendiri
        IF v_report_author_text IS NOT NULL AND v_report_author_text <> NEW.user_id::text THEN
            BEGIN
                v_target_user_id := v_report_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_header := 'Laporan Anda Mendapat Dukungan!';
                v_child := 'laporan ' || COALESCE(v_report_title, 'Anda') || ' mendapat dukungan. ketuk untuk melihat';

                -- Simpan ke in-app inbox
                INSERT INTO public.notifications (user_id, title, message, type, report_id)
                VALUES (v_target_user_id, v_header, v_child, 'upvoted', NEW.report_id);

                -- Enqueue ke FCM
                INSERT INTO public.notification_queue (event_type, payload)
                VALUES (
                    'report_upvoted',
                    jsonb_build_object(
                        'title', v_header,
                        'body', v_child,
                        'recipient_user_ids', jsonb_build_array(v_report_author_text),
                        'report_id', NEW.report_id,
                        'data', jsonb_build_object(
                            'type', 'report_upvoted',
                            'report_id', NEW.report_id
                        )
                    )
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_votes_notification ON public.votes;
CREATE TRIGGER trg_votes_notification
AFTER INSERT OR UPDATE OF vote_type ON public.votes
FOR EACH ROW
EXECUTE FUNCTION public.trg_vote_notification();


-- 5. Trigger Event 4: Pengumuman Baru (User)
-- header = Pengumuman Baru Diterbitkan!
-- child  = lihat pengumuman sekarang.
CREATE OR REPLACE FUNCTION public.trg_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_header TEXT := 'Pengumuman Baru Diterbitkan!';
    v_child TEXT := 'lihat pengumuman sekarang.';
BEGIN
    IF NEW.is_published = true AND (TG_OP = 'INSERT' OR OLD.is_published = false) THEN
        -- 1. Insert ke in-app inbox notifikasi semua pengguna
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        SELECT 
            p.id,
            v_header,
            v_child,
            'announcement',
            NULL
        FROM public.profiles p;

        -- 2. Insert ke antrean push notification FCM broadcast
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'announcement_published',
            jsonb_build_object(
                'title', v_header,
                'body', v_child,
                'broadcast', true,
                'announcement_id', NEW.id,
                'data', jsonb_build_object(
                    'type', 'announcement_published',
                    'announcement_id', NEW.id
                )
            )
        );
    END IF;
    RETURN NEW;
END;
$$;


-- 6. Trigger Event 5: Laporan Baru Dibuat (Admin)
-- header = Laporan Baru!
-- child  = buka laporan sekarang.
CREATE OR REPLACE FUNCTION public.trg_new_report_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_header TEXT := 'Laporan Baru!';
    v_child TEXT := 'buka laporan sekarang.';
BEGIN
    -- Hanya kirim jika bukan draft dan belum dihapus
    IF (NEW.is_draft IS NOT TRUE) AND NEW.deleted_at IS NULL THEN
        -- 1. Insert ke in-app inbox notifikasi semua admin
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        SELECT 
            p.id,
            v_header,
            v_child,
            'new_report',
            NEW.id
        FROM public.profiles p
        WHERE p.role = 'admin';

        -- 2. Insert ke antrean push notification FCM untuk target role admin
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'new_report_created',
            jsonb_build_object(
                'title', v_header,
                'body', v_child,
                'target_role', 'admin',
                'report_id', NEW.id,
                'data', jsonb_build_object(
                    'type', 'new_report',
                    'report_id', NEW.id
                )
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_insert_notification ON public.reports;
CREATE TRIGGER trg_reports_insert_notification
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.trg_new_report_notification();
