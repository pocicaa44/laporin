-- Migration: Ensure author avatar and profile sync from public.profiles on both INSERT and UPDATE
-- for both reports and comments. Also backfills existing reports and comments.

CREATE OR REPLACE FUNCTION public.sync_profile_to_reports()
RETURNS TRIGGER AS $$
BEGIN
    -- Sync author avatar, username, and full name to reports
    UPDATE public.reports
    SET 
        author_avatar_url = NEW.avatar_url,
        author_username = COALESCE(NEW.username, author_username),
        author_name = COALESCE(NULLIF(NEW.full_name, ''), author_name)
    WHERE author_id = NEW.id::text;

    -- Sync author avatar to comments
    UPDATE public.comments
    SET 
        author_avatar_url = NEW.avatar_url
    WHERE author_id = NEW.id::text;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_profile_to_reports ON public.profiles;

CREATE TRIGGER trg_sync_profile_to_reports
AFTER INSERT OR UPDATE OF avatar_url, username, full_name ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_profile_to_reports();

-- Backfill reports from profiles for any missing author_avatar_url
UPDATE public.reports r
SET 
    author_avatar_url = p.avatar_url,
    author_username = COALESCE(r.author_username, p.username),
    author_name = COALESCE(NULLIF(p.full_name, ''), r.author_name)
FROM public.profiles p
WHERE r.author_id = p.id::text
  AND p.avatar_url IS NOT NULL
  AND p.avatar_url <> ''
  AND (r.author_avatar_url IS NULL OR r.author_avatar_url = '');

-- Backfill comments from profiles for any missing author_avatar_url
UPDATE public.comments c
SET author_avatar_url = p.avatar_url
FROM public.profiles p
WHERE c.author_id = p.id::text
  AND p.avatar_url IS NOT NULL
  AND p.avatar_url <> ''
  AND (c.author_avatar_url IS NULL OR c.author_avatar_url = '');
