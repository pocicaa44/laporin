-- ==============================================================================
-- Migrasi Supabase: Fix Comments ID Default & Handle New Comment Trigger
-- Sesuai Invarian AGENTS.md, memastikan kolom comments.id otomatis terisi
-- ==============================================================================

-- 1. Berikan nilai DEFAULT pada kolom id di tabel public.comments
ALTER TABLE public.comments ALTER COLUMN id SET DEFAULT ('com-' || gen_random_uuid()::text);

-- 2. Trigger fallback jika id yang dimasukkan adalah NULL atau kosong
CREATE OR REPLACE FUNCTION public.handle_new_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        NEW.id := 'com-' || gen_random_uuid()::text;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_before_insert ON public.comments;
CREATE TRIGGER trg_comments_before_insert
BEFORE INSERT ON public.comments
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_comment();

-- 3. Batasi hak eksekusi function internal
REVOKE EXECUTE ON FUNCTION public.handle_new_comment() FROM PUBLIC, anon, authenticated;

