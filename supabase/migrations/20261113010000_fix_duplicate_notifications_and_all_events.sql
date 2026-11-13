-- ==============================================================================
-- Migrasi Supabase: Perbaikan Duplikasi Notifikasi & Penjaminan Seluruh Event Notifikasi
-- File: 20261113010000_fix_duplicate_notifications_and_all_events.sql
--
-- Target Perbaikan:
-- 1. Mengeliminasi duplikasi trigger perubahan status laporan (mencegah notifikasi dobel).
-- 2. Memasang dan mengaktifkan trigger untuk seluruh 6 event notifikasi yang disyaratkan:
--    a. Laporan baru (admin) -> type: 'new_report'
--    b. Perubahan status laporan (user/pelapor) -> type: 'status_changed'
--    c. Vote/dukungan laporan (user/pelapor) -> type: 'upvoted'
--    d. Komentar masuk pada laporan (user/pelapor) -> type: 'new_comment'
--    e. Balas komentar (admin, user) -> type: 'reply_comment'
--    f. Pengumuman baru diterbitkan (admin, user) -> type: 'announcement'
-- 3. Mencegah duplikasi insert pada level database dengan idempotency window (5 detik).
-- 4. Membersihkan data duplikat yang sebelumnya terlanjur tersimpan di tabel public.notifications.
-- 5. Memastikan tabel public.notifications terdaftar pada publication supabase_realtime.
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. PEMBERSIHAN TRIGGER LAMA & DATA DUPLIKAT
-- ------------------------------------------------------------------------------

-- Hapus seluruh variasi nama trigger pada tabel reports, votes, comments, announcements
DROP TRIGGER IF EXISTS trg_reports_status_notification ON public.reports;
DROP TRIGGER IF EXISTS trg_notify_report_status_changed ON public.reports;
DROP TRIGGER IF EXISTS trg_reports_insert_notification ON public.reports;
DROP TRIGGER IF EXISTS trg_notify_new_report ON public.reports;

DROP TRIGGER IF EXISTS trg_votes_notification ON public.votes;
DROP TRIGGER IF EXISTS trg_notify_vote ON public.votes;

DROP TRIGGER IF EXISTS trg_comments_notification ON public.comments;
DROP TRIGGER IF EXISTS trg_notify_comment ON public.comments;

DROP TRIGGER IF EXISTS trg_announcements_notification ON public.announcements;
DROP TRIGGER IF EXISTS trg_notify_announcement ON public.announcements;

-- Bersihkan baris duplikat yang terlanjur terbentuk di tabel public.notifications
DELETE FROM public.notifications a
USING public.notifications b
WHERE a.id > b.id
  AND a.user_id = b.user_id
  AND a.type = b.type
  AND COALESCE(a.report_id, '') = COALESCE(b.report_id, '')
  AND abs(extract(epoch from (a.created_at - b.created_at))) < 10;


-- ------------------------------------------------------------------------------
-- 2. EVENT 1: PERUBAHAN STATUS LAPORAN (USER / PELAPOR)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_report_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_status_label TEXT;
    v_title TEXT;
    v_msg TEXT;
    v_report_num TEXT;
    v_author_uuid UUID;
BEGIN
    IF OLD.handling_status IS DISTINCT FROM NEW.handling_status 
       AND (NEW.is_draft IS NOT TRUE)
       AND NEW.deleted_at IS NULL THEN
        
        -- Validasi UUID author_id laporan
        BEGIN
            v_author_uuid := NEW.author_id::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_author_uuid := NULL;
        END;

        IF v_author_uuid IS NOT NULL THEN
            v_report_num := COALESCE(NEW.report_number, substring(NEW.id::text from 1 for 8));
            
            CASE NEW.handling_status
                WHEN 'accepted' THEN 
                    v_title := 'Status laporan Anda diperbarui!';
                    v_status_label := 'Diterima';
                    v_msg := 'Laporan #' || v_report_num || ' telah diverifikasi dan diterima oleh admin.';
                WHEN 'in_progress' THEN 
                    v_title := 'Status laporan Anda diperbarui!';
                    v_status_label := 'Diproses';
                    v_msg := 'Laporan #' || v_report_num || ' sedang dalam penanganan petugas.';
                WHEN 'completed' THEN 
                    v_title := 'Laporan Anda telah diselesaikan!';
                    v_status_label := 'Selesai';
                    v_msg := 'Laporan #' || v_report_num || ' telah selesai ditangani. Terima kasih atas partisipasi Anda!';
                WHEN 'rejected' THEN 
                    v_title := 'Laporan Anda ditolak!';
                    v_status_label := 'Ditolak';
                    v_msg := 'Laporan #' || v_report_num || ' tidak dapat diproses: ' || COALESCE(NEW.rejection_reason, 'Tidak memenuhi kriteria.');
                WHEN 'cancelled' THEN 
                    v_title := 'Status laporan Anda diperbarui!';
                    v_status_label := 'Dibatalkan';
                    v_msg := 'Laporan #' || v_report_num || ' telah dibatalkan.';
                ELSE 
                    v_title := 'Status laporan Anda diperbarui!';
                    v_status_label := NEW.handling_status;
                    v_msg := 'Status laporan #' || v_report_num || ' diperbarui menjadi ' || NEW.handling_status || '.';
            END CASE;

            -- 1. Insert TUNGGAL ke in-app inbox notifications (idempoten dengan window 5 detik)
            IF NOT EXISTS (
                SELECT 1 FROM public.notifications
                WHERE user_id = v_author_uuid
                  AND type = 'status_changed'
                  AND report_id = NEW.id
                  AND created_at > now() - interval '5 seconds'
            ) THEN
                INSERT INTO public.notifications (user_id, title, message, type, report_id)
                VALUES (
                    v_author_uuid,
                    v_title,
                    v_msg,
                    'status_changed',
                    NEW.id
                );
            END IF;

            -- 2. Insert ke antrean push notification FCM
            INSERT INTO public.notification_queue (event_type, payload)
            VALUES (
                'report_status_changed',
                jsonb_build_object(
                    'title', v_title,
                    'body', v_msg,
                    'recipient_user_ids', jsonb_build_array(NEW.author_id),
                    'report_id', NEW.id,
                    'data', jsonb_build_object(
                        'type', 'status_changed',
                        'notification_type', 'status_changed',
                        'report_id', NEW.id,
                        'handling_status', NEW.handling_status
                    )
                )
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

-- Pasang hanya SATU trigger tunggal untuk status update
CREATE TRIGGER trg_notify_report_status_changed
AFTER UPDATE OF handling_status ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.trg_report_status_notification();


-- ------------------------------------------------------------------------------
-- 3. EVENT 2: LAPORAN BARU DIBUAT (ADMIN)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_new_report_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_header TEXT := 'Laporan Baru!';
    v_child TEXT;
BEGIN
    IF (NEW.is_draft IS NOT TRUE) AND NEW.deleted_at IS NULL THEN
        v_child := 'Laporan "' || COALESCE(NEW.title, 'Tanpa Judul') || '" baru saja dikirim warga.';

        -- 1. Insert ke in-app inbox seluruh admin aktif
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        SELECT 
            p.id,
            v_header,
            v_child,
            'new_report',
            NEW.id
        FROM public.profiles p
        WHERE p.role = 'admin'
          AND NOT EXISTS (
              SELECT 1 FROM public.notifications n
              WHERE n.user_id = p.id
                AND n.type = 'new_report'
                AND n.report_id = NEW.id
                AND n.created_at > now() - interval '5 seconds'
          );

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

CREATE TRIGGER trg_notify_new_report
AFTER INSERT ON public.reports
FOR EACH ROW
EXECUTE FUNCTION public.trg_new_report_notification();


-- ------------------------------------------------------------------------------
-- 4. EVENT 3: VOTE / DUKUNGAN WARGA (USER / PELAPOR)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_vote_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_report_author_text TEXT;
    v_report_title TEXT;
    v_target_user_id UUID;
    v_header TEXT := 'Seseorang mendukung laporan Anda!';
    v_child TEXT;
BEGIN
    IF NEW.vote_type = 'up' AND (TG_OP = 'INSERT' OR OLD.vote_type IS DISTINCT FROM 'up') THEN
        SELECT author_id, title INTO v_report_author_text, v_report_title
        FROM public.reports
        WHERE id = NEW.report_id;

        -- Notifikasi hanya dikirim ke pelapor jika pemberi vote bukan pelapor itu sendiri
        IF v_report_author_text IS NOT NULL AND v_report_author_text <> NEW.user_id::text THEN
            BEGIN
                v_target_user_id := v_report_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_child := 'Laporan "' || COALESCE(v_report_title, 'Anda') || '" mendapat dukungan warga.';

                -- Simpan ke in-app inbox
                IF NOT EXISTS (
                    SELECT 1 FROM public.notifications
                    WHERE user_id = v_target_user_id
                      AND type = 'upvoted'
                      AND report_id = NEW.report_id
                      AND created_at > now() - interval '5 seconds'
                ) THEN
                    INSERT INTO public.notifications (user_id, title, message, type, report_id)
                    VALUES (v_target_user_id, v_header, v_child, 'upvoted', NEW.report_id);
                END IF;

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

CREATE TRIGGER trg_notify_vote
AFTER INSERT OR UPDATE OF vote_type ON public.votes
FOR EACH ROW
EXECUTE FUNCTION public.trg_vote_notification();


-- ------------------------------------------------------------------------------
-- 5. EVENT 4 & 5: KOMENTAR BARU & BALASAN KOMENTAR (USER & ADMIN)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_target_user_id UUID;
    v_header TEXT;
    v_child TEXT;
    v_event_type TEXT;
    v_notif_type TEXT;
    v_parent_author_text TEXT;
    v_report_author_text TEXT;
    v_report_title TEXT;
    v_sender_name TEXT;
BEGIN
    IF NEW.deleted_at IS NOT NULL THEN
        RETURN NEW;
    END IF;

    v_sender_name := COALESCE(NEW.author_name, 'Seseorang');

    IF NEW.parent_comment_id IS NOT NULL THEN
        -- Event 5: Balasan Komentar (Bisa untuk Admin maupun Warga pembuat komentar induk)
        SELECT author_id INTO v_parent_author_text
        FROM public.comments
        WHERE id = NEW.parent_comment_id;

        IF v_parent_author_text IS NOT NULL AND v_parent_author_text <> NEW.author_id THEN
            BEGIN
                v_target_user_id := v_parent_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_header := 'Seseorang membalas komentar Anda!';
                v_child := v_sender_name || ' membalas komentar Anda: "' || substring(NEW.body from 1 for 80) || '"';
                v_event_type := 'reply_comment';
                v_notif_type := 'reply_comment';

                IF NOT EXISTS (
                    SELECT 1 FROM public.notifications
                    WHERE user_id = v_target_user_id
                      AND type = v_notif_type
                      AND report_id = NEW.report_id
                      AND created_at > now() - interval '5 seconds'
                ) THEN
                    INSERT INTO public.notifications (user_id, title, message, type, report_id)
                    VALUES (v_target_user_id, v_header, v_child, v_notif_type, NEW.report_id);
                END IF;

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
        -- Event 4: Komentar Baru pada Laporan (Terkirim ke Pemilik Laporan)
        SELECT author_id, title INTO v_report_author_text, v_report_title
        FROM public.reports
        WHERE id = NEW.report_id;

        IF v_report_author_text IS NOT NULL AND v_report_author_text <> NEW.author_id THEN
            BEGIN
                v_target_user_id := v_report_author_text::uuid;
            EXCEPTION WHEN OTHERS THEN
                v_target_user_id := NULL;
            END;

            IF v_target_user_id IS NOT NULL THEN
                v_header := 'Seseorang mengomentari laporan Anda!';
                v_child := v_sender_name || ' mengomentari laporan ' || COALESCE(v_report_title, '') || ': "' || substring(NEW.body from 1 for 80) || '"';
                v_event_type := 'new_comment';
                v_notif_type := 'new_comment';

                IF NOT EXISTS (
                    SELECT 1 FROM public.notifications
                    WHERE user_id = v_target_user_id
                      AND type = v_notif_type
                      AND report_id = NEW.report_id
                      AND created_at > now() - interval '5 seconds'
                ) THEN
                    INSERT INTO public.notifications (user_id, title, message, type, report_id)
                    VALUES (v_target_user_id, v_header, v_child, v_notif_type, NEW.report_id);
                END IF;

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

CREATE TRIGGER trg_notify_comment
AFTER INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.trg_comment_notification();


-- ------------------------------------------------------------------------------
-- 6. EVENT 6: PENGUMUMAN BARU DITERBITKAN (ADMIN & USER)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_header TEXT := 'Pengumuman baru diterbitkan!';
    v_child TEXT;
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE) OR
       (TG_OP = 'UPDATE' AND OLD.is_published = FALSE AND NEW.is_published = TRUE) THEN
        v_child := COALESCE(NEW.title, 'Pengumuman resmi telah diterbitkan.');

        -- 1. Insert ke in-app inbox notifikasi SEMUA pengguna (warga & admin)
        INSERT INTO public.notifications (user_id, title, message, type, report_id)
        SELECT 
            p.id,
            v_header,
            v_child,
            'announcement',
            NULL
        FROM public.profiles p
        WHERE NOT EXISTS (
            SELECT 1 FROM public.notifications n
            WHERE n.user_id = p.id
              AND n.type = 'announcement'
              AND n.created_at > now() - interval '5 seconds'
        );

        -- 2. Insert ke antrean push notification FCM broadcast
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'announcement_broadcast',
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

CREATE TRIGGER trg_notify_announcement
AFTER INSERT OR UPDATE OF is_published ON public.announcements
FOR EACH ROW
EXECUTE FUNCTION public.trg_announcement_notification();


-- ------------------------------------------------------------------------------
-- 7. AKTIFKAN REPLIKASI REALTIME PADA TABEL NOTIFICATIONS
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    EXCEPTION WHEN duplicate_object THEN
        NULL;
    END;
END $$;

COMMIT;
