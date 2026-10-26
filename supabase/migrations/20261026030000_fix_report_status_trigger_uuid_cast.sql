-- ==============================================================================
-- Migrasi Supabase: Perbaikan Type Cast UUID pada Trigger Status Laporan
-- Mengatasi Error Postgres 42804: column "user_id" is of type uuid but expression is of type text
-- ==============================================================================

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
    v_author_uuid UUID;
BEGIN
    IF OLD.handling_status IS DISTINCT FROM NEW.handling_status 
       AND (NEW.is_draft IS NOT TRUE)
       AND NEW.deleted_at IS NULL THEN
        
        v_status_label := public.format_handling_status_label(NEW.handling_status);
        v_header := 'Status Laporan Diperbarui!';
        v_child := 'laporan ' || COALESCE(NEW.title, '') || ' ' || v_status_label;

        -- Konversi yang aman dari TEXT ke UUID untuk field user_id tabel notifications
        BEGIN
            v_author_uuid := NEW.author_id::uuid;
        EXCEPTION WHEN OTHERS THEN
            v_author_uuid := NULL;
        END;

        -- 1. Insert ke inbox in-app notifications pemilik laporan jika valid UUID
        IF v_author_uuid IS NOT NULL THEN
            INSERT INTO public.notifications (user_id, title, message, type, report_id)
            VALUES (
                v_author_uuid,
                v_header,
                v_child,
                'status_changed',
                NEW.id
            );
        END IF;

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
