-- ==============================================================================
-- Migrasi Supabase: Tabel Comments, RLS Policies, dan Triggers
-- Sesuai PRD.md Bagian 7.7, FR-06 & AGENTS.md Invarian 3.1 - 3.4
-- ==============================================================================

-- 1. Tabel comments
CREATE TABLE IF NOT EXISTS public.comments (
    id TEXT PRIMARY KEY,
    report_id TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL DEFAULT 'Warga',
    author_avatar_url TEXT,
    author_role TEXT NOT NULL DEFAULT 'user' CHECK (author_role IN ('user', 'admin')),
    body TEXT NOT NULL,
    parent_comment_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_comments_report_id ON public.comments(report_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON public.comments(created_at);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON public.comments(author_id);

-- 2. Row Level Security (RLS) pada tabel comments
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow reading comments on public reports"
ON public.comments FOR SELECT
TO authenticated, anon
USING (
    deleted_at IS NULL
    AND EXISTS (
        SELECT 1 FROM public.reports r
        WHERE r.id = report_id
          AND (
            (r.publication_state = 'published' AND r.handling_status NOT IN ('rejected', 'cancelled'))
            OR (auth.uid() IS NOT NULL AND r.author_id = auth.uid()::text)
            OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
          )
    )
);

CREATE POLICY "Authenticated users can insert comments on active reports"
ON public.comments FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() IS NOT NULL
    AND author_id = auth.uid()::text
    AND EXISTS (
        SELECT 1 FROM public.reports r
        WHERE r.id = report_id
          AND r.publication_state = 'published'
          AND r.handling_status NOT IN ('rejected', 'cancelled')
    )
);

CREATE POLICY "Users can update their own comments"
ON public.comments FOR UPDATE
TO authenticated
USING (author_id = auth.uid()::text OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'))
WITH CHECK (author_id = auth.uid()::text OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

CREATE POLICY "Users can delete their own comments"
ON public.comments FOR DELETE
TO authenticated
USING (author_id = auth.uid()::text OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'));

-- 3. Trigger Sebelum Insert: Menjamin author_id, author_role, author_name dari Auth Session
CREATE OR REPLACE FUNCTION public.handle_new_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_role TEXT := 'user';
    v_user_name TEXT := 'Warga';
    v_avatar TEXT := NULL;
BEGIN
    IF auth.uid() IS NOT NULL THEN
        NEW.author_id := auth.uid()::text;
        SELECT role, COALESCE(full_name, username, 'Warga'), avatar_url
        INTO v_user_role, v_user_name, v_avatar
        FROM public.profiles
        WHERE id = auth.uid();

        IF FOUND THEN
            NEW.author_role := COALESCE(v_user_role, 'user');
            IF NEW.author_name IS NULL OR NEW.author_name = '' OR NEW.author_name = 'Warga' OR NEW.author_name = 'Warga Laporin' THEN
                NEW.author_name := COALESCE(v_user_name, 'Warga');
            END IF;
            IF NEW.author_avatar_url IS NULL THEN
                NEW.author_avatar_url := v_avatar;
            END IF;
        END IF;
    END IF;

    IF NEW.id IS NULL OR NEW.id = '' THEN
        NEW.id := 'com-' || extract(epoch from now())::bigint || '-' || substr(md5(random()::text), 1, 6);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_before_insert ON public.comments;
CREATE TRIGGER trg_comments_before_insert
BEFORE INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_comment();

-- 4. Trigger Setelah Insert/Update/Delete: Update comments_count pada reports secara atomik
CREATE OR REPLACE FUNCTION public.update_report_comments_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_report_id TEXT;
    v_count INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_report_id := OLD.report_id;
    ELSE
        v_report_id := NEW.report_id;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM public.comments
    WHERE report_id = v_report_id AND deleted_at IS NULL;

    UPDATE public.reports
    SET comments_count = v_count,
        updated_at = now()
    WHERE id = v_report_id;

    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_comment_count ON public.comments;
CREATE TRIGGER trg_comment_count
AFTER INSERT OR UPDATE OF deleted_at OR DELETE
ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.update_report_comments_count();
