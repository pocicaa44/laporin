-- Migration: Add author profile columns to reports and trigger to auto-sync from profiles
-- Date: 2026-10-24

ALTER TABLE public.reports 
    ADD COLUMN IF NOT EXISTS author_avatar_url TEXT,
    ADD COLUMN IF NOT EXISTS author_username TEXT;

-- Backfill existing reports from profiles table
UPDATE public.reports r
SET 
    author_avatar_url = p.avatar_url,
    author_username = p.username
FROM public.profiles p
WHERE r.author_id = p.id::text;

-- Function to automatically sync avatar, username, and full_name changes to reports
CREATE OR REPLACE FUNCTION public.sync_profile_to_reports()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.reports
    SET 
        author_avatar_url = NEW.avatar_url,
        author_username = NEW.username,
        author_name = COALESCE(NULLIF(NEW.full_name, ''), author_name)
    WHERE author_id = NEW.id::text;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on public.profiles
CREATE OR REPLACE TRIGGER trg_sync_profile_to_reports
AFTER UPDATE OF avatar_url, username, full_name ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_profile_to_reports();
