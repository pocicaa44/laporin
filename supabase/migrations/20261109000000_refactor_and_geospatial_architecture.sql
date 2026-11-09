-- ==============================================================================
-- LAPORIN MASTER DATABASE REFACTORING & POSTGIS GEOSPATIAL ARCHITECTURE
-- Migration: 20261109000000_refactor_and_geospatial_architecture.sql
--
-- Domain Coverage:
-- 1. Administrative Regions & PostGIS Spatial Architecture (All Indonesia Hierarchy)
-- 2. Profiles & Supabase Auth Sync with Role Protection
-- 3. Reports Management (Dual State Machine, Spatial Points, Administrative FKs)
-- 4. Social Interactions (Unique Votes, Nested Comments)
-- 5. Announcements, Device Tokens & Notifications Inbox
-- 6. High-Performance Indexing (Spatial GiST, Covering Partial B-Tree)
-- 7. Secure Row Level Security (RLS) with InitPlan Optimization (select auth.uid())
-- 8. Hardened RPCs and Triggers with safe search_path and restricted EXECUTE privileges
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS & SPATIAL SECURITY
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "postgis" WITH SCHEMA public;

-- ------------------------------------------------------------------------------
-- 2. ADMINISTRATIVE REGIONS (POSTGIS GEOSPATIAL EXPANSION)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.administrative_regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    level VARCHAR(20) NOT NULL CHECK (level IN ('country', 'province', 'regency', 'district', 'village')),
    parent_id UUID REFERENCES public.administrative_regions(id) ON DELETE RESTRICT,
    boundary GEOMETRY(MultiPolygon, 4326),
    center_point GEOGRAPHY(Point, 4326),
    source VARCHAR(100) DEFAULT 'KEMENDAGRI/BPS',
    boundary_status VARCHAR(30) DEFAULT 'verified',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_admin_regions_boundary ON public.administrative_regions USING GIST(boundary);
CREATE INDEX IF NOT EXISTS idx_admin_regions_center ON public.administrative_regions USING GIST(center_point);
CREATE INDEX IF NOT EXISTS idx_admin_regions_parent ON public.administrative_regions(parent_id);
CREATE INDEX IF NOT EXISTS idx_admin_regions_level ON public.administrative_regions(level);
CREATE INDEX IF NOT EXISTS idx_admin_regions_code ON public.administrative_regions(code);

ALTER TABLE public.administrative_regions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow read administrative regions for all" ON public.administrative_regions;
CREATE POLICY "Allow read administrative regions for all"
ON public.administrative_regions FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Admins can manage administrative regions" ON public.administrative_regions;
CREATE POLICY "Admins can manage administrative regions"
ON public.administrative_regions FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- ------------------------------------------------------------------------------
-- 3. PROFILES & USER MANAGEMENT
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT NOT NULL DEFAULT 'Warga Laporin',
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    assigned_area_ids TEXT[] DEFAULT '{}'::text[],
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Profiles are viewable by everyone"
ON public.profiles FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = (SELECT auth.uid()))
WITH CHECK (
    id = (SELECT auth.uid())
    AND (
        -- User biasa tidak boleh menaikkan role dirinya sendiri menjadi admin
        role = (SELECT p.role FROM public.profiles p WHERE p.id = (SELECT auth.uid()))
        OR (SELECT p.role FROM public.profiles p WHERE p.id = (SELECT auth.uid())) = 'admin'
    )
);

-- Trigger: Otomatis sinkronisasi user baru dari auth.users ke public.profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_full_name TEXT;
    v_avatar_url TEXT;
    v_username TEXT;
BEGIN
    v_full_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1),
        'Warga Laporin'
    );
    v_avatar_url := COALESCE(
        NEW.raw_user_meta_data->>'avatar_url',
        NEW.raw_user_meta_data->>'picture',
        NEW.raw_user_meta_data->>'photo_url'
    );
    v_username := NEW.raw_user_meta_data->>'user_name';

    INSERT INTO public.profiles (id, full_name, avatar_url, username, role)
    VALUES (NEW.id, v_full_name, v_avatar_url, v_username, 'user')
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url),
        updated_at = timezone('utc'::text, now());

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

-- ------------------------------------------------------------------------------
-- 4. REPORTS MANAGEMENT
-- ------------------------------------------------------------------------------
-- Pastikan kolom geospasial dan foreign key wilayah ada di reports
DO $$
BEGIN
    -- Tambah kolom lokasi PostGIS jika belum ada
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'location'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN location GEOGRAPHY(Point, 4326);
    END IF;

    -- Tambah referensi wilayah administratif
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'province_id'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN province_id UUID REFERENCES public.administrative_regions(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'city_id'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN city_id UUID REFERENCES public.administrative_regions(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'district_id'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN district_id UUID REFERENCES public.administrative_regions(id) ON DELETE SET NULL;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'village_id'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN village_id UUID REFERENCES public.administrative_regions(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Trigger: Sinkronisasi otomatis POINT geografis dari latitude dan longitude laporan
-- serta penentuan wilayah administratif otomatis di sisi server (PostGIS)
CREATE OR REPLACE FUNCTION public.trg_reports_sync_location()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_point GEOMETRY;
    v_geog GEOGRAPHY;
    v_prov RECORD;
    v_city RECORD;
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
        v_point := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
        v_geog := NEW.location;

        -- Auto-resolve province jika belum diisi
        IF NEW.province_id IS NULL THEN
            SELECT id, code, name INTO v_prov
            FROM public.administrative_regions
            WHERE level = 'province' AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
            LIMIT 1;

            IF v_prov.id IS NOT NULL THEN
                NEW.province_id := v_prov.id;
                NEW.area_id := 'area-' || lower(v_prov.code);
                NEW.area_name := v_prov.name;
            END IF;
        END IF;

        -- Auto-resolve regency/city jika belum diisi
        IF NEW.city_id IS NULL AND NEW.province_id IS NOT NULL THEN
            SELECT id, code, name INTO v_city
            FROM public.administrative_regions
            WHERE level = 'regency' AND parent_id = NEW.province_id AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
            LIMIT 1;

            IF v_city.id IS NULL THEN
                SELECT id, code, name INTO v_city
                FROM public.administrative_regions
                WHERE level = 'regency' AND parent_id = NEW.province_id AND center_point IS NOT NULL
                ORDER BY ST_Distance(center_point, v_geog) ASC
                LIMIT 1;
            END IF;

            IF v_city.id IS NOT NULL THEN
                NEW.city_id := v_city.id;
            END IF;
        END IF;
    END IF;

    NEW.updated_at := timezone('utc'::text, now());
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_reports_location_sync ON public.reports;
CREATE TRIGGER trg_reports_location_sync
    BEFORE INSERT OR UPDATE OF latitude, longitude ON public.reports
    FOR EACH ROW EXECUTE FUNCTION public.trg_reports_sync_location();

REVOKE EXECUTE ON FUNCTION public.trg_reports_sync_location() FROM PUBLIC, anon, authenticated;

-- Indexes performa tinggi pada reports
CREATE INDEX IF NOT EXISTS idx_reports_spatial_location ON public.reports USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_reports_public_feed ON public.reports (publication_state, handling_status, created_at DESC) 
    WHERE (deleted_at IS NULL AND deleted_by_user = FALSE AND deleted_by_admin = FALSE AND is_draft = FALSE);
CREATE INDEX IF NOT EXISTS idx_reports_author_created ON public.reports (author_id, is_draft, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON public.reports (handling_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reports_province_id ON public.reports(province_id);
CREATE INDEX IF NOT EXISTS idx_reports_city_id ON public.reports(city_id);

-- RLS Policies pada reports dengan optimasi (SELECT auth.uid())
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read active published reports" ON public.reports;
DROP POLICY IF EXISTS "Public visible reports or own reports are viewable" ON public.reports;
CREATE POLICY "Public can read active published reports"
ON public.reports FOR SELECT
TO authenticated, anon
USING (
    (
        deleted_at IS NULL
        AND deleted_by_user = FALSE
        AND deleted_by_admin = FALSE
        AND is_draft = FALSE
        AND publication_state = 'published'
        AND handling_status NOT IN ('rejected', 'cancelled')
    )
    OR (
        (SELECT auth.uid()) IS NOT NULL 
        AND author_id = (SELECT auth.uid())::text 
        AND deleted_by_user = FALSE
    )
    OR (
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
        )
        AND deleted_by_admin = FALSE
    )
);

DROP POLICY IF EXISTS "Authenticated users can insert reports" ON public.reports;
CREATE POLICY "Authenticated users can insert reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
    author_id = (SELECT auth.uid())::text
    AND NOT EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Authors can update own reports" ON public.reports;
CREATE POLICY "Authors can update own reports"
ON public.reports FOR UPDATE
TO authenticated
USING (
    (author_id = (SELECT auth.uid())::text AND deleted_by_user = FALSE)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
)
WITH CHECK (
    (author_id = (SELECT auth.uid())::text AND deleted_by_user = FALSE)
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Allow permanent delete when both user and admin deleted" ON public.reports;
DROP POLICY IF EXISTS "Allow delete for admin or dual party" ON public.reports;
CREATE POLICY "Allow permanent delete when both user and admin deleted"
ON public.reports FOR DELETE
TO authenticated
USING (
    (deleted_by_user = TRUE AND deleted_by_admin = TRUE)
    OR (
        EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
        ) AND deleted_by_user = TRUE
    )
    OR (
        (SELECT auth.uid()) IS NOT NULL 
        AND author_id = (SELECT auth.uid())::text 
        AND deleted_by_admin = TRUE
    )
);

-- ------------------------------------------------------------------------------
-- 5. SOCIAL INTERACTIONS (VOTES & COMMENTS)
-- ------------------------------------------------------------------------------
-- Pastikan Unique Constraint pada votes (report_id, user_id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'votes_report_user_unique'
    ) THEN
        ALTER TABLE public.votes ADD CONSTRAINT votes_report_user_unique UNIQUE (report_id, user_id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_votes_report_user ON public.votes(report_id, user_id);
CREATE INDEX IF NOT EXISTS idx_votes_user_id ON public.votes(user_id);

ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view votes" ON public.votes;
DROP POLICY IF EXISTS "Public can read votes" ON public.votes;
CREATE POLICY "Public can read votes"
ON public.votes FOR SELECT
TO authenticated, anon
USING (true);

DROP POLICY IF EXISTS "Users can insert their own vote" ON public.votes;
CREATE POLICY "Users can insert their own vote"
ON public.votes FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own vote" ON public.votes;
CREATE POLICY "Users can update their own vote"
ON public.votes FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete their own vote" ON public.votes;
CREATE POLICY "Users can delete their own vote"
ON public.votes FOR DELETE
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- Indexing pada Comments
CREATE INDEX IF NOT EXISTS idx_comments_report_created ON public.comments(report_id, created_at ASC) WHERE (deleted_at IS NULL);
CREATE INDEX IF NOT EXISTS idx_comments_author_id ON public.comments(author_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON public.comments(parent_comment_id);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow reading comments on public reports" ON public.comments;
CREATE POLICY "Allow reading comments on public reports"
ON public.comments FOR SELECT
TO authenticated, anon
USING (
    deleted_at IS NULL
    AND EXISTS (
        SELECT 1 FROM public.reports r 
        WHERE r.id = comments.report_id
        AND r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.publication_state = 'published'
        AND r.handling_status NOT IN ('rejected', 'cancelled')
    )
);

DROP POLICY IF EXISTS "Authenticated users can insert comments on active reports" ON public.comments;
CREATE POLICY "Authenticated users can insert comments on active reports"
ON public.comments FOR INSERT
TO authenticated
WITH CHECK (
    author_id = (SELECT auth.uid())::text
    AND EXISTS (
        SELECT 1 FROM public.reports r 
        WHERE r.id = comments.report_id
        AND r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.is_discussion_active = TRUE
        AND r.handling_status NOT IN ('rejected', 'cancelled')
    )
);

DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
CREATE POLICY "Users can update their own comments"
ON public.comments FOR UPDATE
TO authenticated
USING (author_id = (SELECT auth.uid())::text)
WITH CHECK (author_id = (SELECT auth.uid())::text);

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;
CREATE POLICY "Users can delete their own comments"
ON public.comments FOR DELETE
TO authenticated
USING (
    author_id = (SELECT auth.uid())::text
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- ------------------------------------------------------------------------------
-- 6. ANNOUNCEMENTS, DEVICE TOKENS & NOTIFICATIONS
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_announcements_author_id ON public.announcements(author_id);
CREATE INDEX IF NOT EXISTS idx_announcements_published_created ON public.announcements(is_published, created_at DESC);

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read published announcements" ON public.announcements;
DROP POLICY IF EXISTS "Public can read published announcements" ON public.announcements;
CREATE POLICY "Public can read published announcements"
ON public.announcements FOR SELECT
TO authenticated, anon
USING (
    is_published = TRUE
    OR EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Admins can insert announcements" ON public.announcements;
CREATE POLICY "Admins can insert announcements"
ON public.announcements FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Admins can update announcements" ON public.announcements;
CREATE POLICY "Admins can update announcements"
ON public.announcements FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

DROP POLICY IF EXISTS "Admins can delete announcements" ON public.announcements;
CREATE POLICY "Admins can delete announcements"
ON public.announcements FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- Device Tokens
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON public.device_tokens(token);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can view their own device tokens"
ON public.device_tokens FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can insert their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can insert their own device tokens"
ON public.device_tokens FOR INSERT
TO authenticated
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can update their own device tokens"
ON public.device_tokens FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete their own device tokens" ON public.device_tokens;
CREATE POLICY "Users can delete their own device tokens"
ON public.device_tokens FOR DELETE
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- Notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_report_id ON public.notifications(report_id);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (user_id = (SELECT auth.uid()))
WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications"
ON public.notifications FOR DELETE
TO authenticated
USING (user_id = (SELECT auth.uid()));

-- Notification Queue
CREATE INDEX IF NOT EXISTS idx_notif_queue_pending ON public.notification_queue(status, created_at ASC) WHERE status = 'pending';
ALTER TABLE public.notification_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view notification queue" ON public.notification_queue;
CREATE POLICY "Admins can view notification queue"
ON public.notification_queue FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

-- ------------------------------------------------------------------------------
-- 7. SECURE FUNCTIONS & RPCS (HARDENED SEARCH PATH & RESTRICTED PRIVILEGES)
-- ------------------------------------------------------------------------------

-- Drop existing functions to allow signature and return type changes cleanly
DROP FUNCTION IF EXISTS public.mark_all_notifications_read();
DROP FUNCTION IF EXISTS public.vote_report(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.execute_dual_party_deletion(TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS public.delete_report_dual_party(TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS public.delete_report_dual_party(UUID, BOOLEAN);
DROP FUNCTION IF EXISTS public.upsert_device_token(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.delete_device_token(TEXT);
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;
DROP FUNCTION IF EXISTS public.validate_report_location(DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.resolve_report_region(DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.get_nearby_feed(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INT);
DROP FUNCTION IF EXISTS public.get_regional_feed(UUID, INT);
DROP FUNCTION IF EXISTS public.is_in_central_java(DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.trg_validate_report_central_java() CASCADE;
DROP FUNCTION IF EXISTS public.format_handling_status_label(TEXT);
DROP FUNCTION IF EXISTS public.sync_profile_to_reports() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_comment() CASCADE;

-- RPC: Cek peran admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid()) AND role = 'admin'
    );
$$;

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- RPC: Atomic Voting dengan Kalkulasi Threshold Downvote
CREATE OR REPLACE FUNCTION public.vote_report(
    p_report_id TEXT,
    p_vote_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_existing_vote TEXT;
    v_new_vote TEXT;
    v_upvotes INT;
    v_downvotes INT;
    v_total_votes INT;
    v_down_percentage NUMERIC;
    v_current_pub_state TEXT;
    v_new_pub_state TEXT;
    v_mod_reason TEXT;
    v_handling_status TEXT;
    v_is_deleted BOOLEAN;
BEGIN
    v_user_id := (SELECT auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Pengguna harus login untuk memberikan vote.';
    END IF;

    IF p_vote_type NOT IN ('up', 'down') THEN
        RAISE EXCEPTION 'Tipe vote tidak valid: wajib "up" atau "down".';
    END IF;

    -- Kunci baris laporan untuk eksekusi atomik
    SELECT 
        handling_status, publication_state, moderation_reason,
        (deleted_at IS NOT NULL OR deleted_by_user = TRUE OR deleted_by_admin = TRUE)
    INTO 
        v_handling_status, v_current_pub_state, v_mod_reason, v_is_deleted
    FROM public.reports
    WHERE id = p_report_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Laporan dengan id % tidak ditemukan.', p_report_id;
    END IF;

    IF v_is_deleted THEN
        RAISE EXCEPTION 'Laporan yang telah dihapus tidak dapat menerima vote.';
    END IF;

    IF v_handling_status IN ('completed', 'rejected', 'cancelled') THEN
        RAISE EXCEPTION 'Laporan dengan status % sudah ditutup dan tidak dapat menerima vote.', v_handling_status;
    END IF;

    -- Cek vote saat ini
    SELECT vote_type INTO v_existing_vote
    FROM public.votes
    WHERE report_id = p_report_id AND user_id = v_user_id;

    IF v_existing_vote = p_vote_type THEN
        -- Toggle off (cabut vote)
        DELETE FROM public.votes
        WHERE report_id = p_report_id AND user_id = v_user_id;
        v_new_vote := NULL;
    ELSIF v_existing_vote IS NOT NULL THEN
        -- Switch vote
        UPDATE public.votes
        SET vote_type = p_vote_type, updated_at = now()
        WHERE report_id = p_report_id AND user_id = v_user_id;
        v_new_vote := p_vote_type;
    ELSE
        -- Vote baru
        INSERT INTO public.votes (report_id, user_id, vote_type)
        VALUES (p_report_id, v_user_id, p_vote_type);
        v_new_vote := p_vote_type;
    END IF;

    -- Hitung ulang agregat vote resmi dari tabel votes
    SELECT 
        COALESCE(COUNT(*) FILTER (WHERE vote_type = 'up'), 0),
        COALESCE(COUNT(*) FILTER (WHERE vote_type = 'down'), 0)
    INTO v_upvotes, v_downvotes
    FROM public.votes
    WHERE report_id = p_report_id;

    v_total_votes := v_upvotes + v_downvotes;
    v_new_pub_state := v_current_pub_state;

    -- Evaluasi Threshold Downvote (Invarian 3.3: min 10 total, min 6 downvote, >= 70%)
    IF v_total_votes >= 10 AND v_downvotes >= 6 THEN
        v_down_percentage := (v_downvotes::NUMERIC / v_total_votes::NUMERIC) * 100.0;
        IF v_down_percentage >= 70.0 AND v_current_pub_state = 'published' THEN
            v_new_pub_state := 'held';
            v_mod_reason := 'Ambang batas downvote tercapai (' || round(v_down_percentage, 1)::TEXT || '%). Ditahan untuk review moderasi.';
        END IF;
    END IF;

    -- Update tabel reports
    UPDATE public.reports
    SET 
        upvotes_count = v_upvotes,
        downvotes_count = v_downvotes,
        publication_state = v_new_pub_state,
        moderation_reason = COALESCE(v_mod_reason, moderation_reason),
        updated_at = timezone('utc'::text, now())
    WHERE id = p_report_id;

    RETURN jsonb_build_object(
        'report_id', p_report_id,
        'current_user_vote', v_new_vote,
        'upvotes_count', v_upvotes,
        'downvotes_count', v_downvotes,
        'publication_state', v_new_pub_state,
        'moderation_reason', v_mod_reason
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.vote_report(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.vote_report(TEXT, TEXT) FROM anon;

-- RPC: Dual Party Report Deletion
CREATE OR REPLACE FUNCTION public.execute_dual_party_deletion(
    p_report_id TEXT,
    p_is_admin BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_caller_id UUID;
    v_is_real_admin BOOLEAN;
    v_author_id TEXT;
    v_deleted_user BOOLEAN;
    v_deleted_admin BOOLEAN;
    v_status TEXT;
    v_is_permanently_deleted BOOLEAN := FALSE;
BEGIN
    v_caller_id := (SELECT auth.uid());
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan untuk menghapus laporan.';
    END IF;

    SELECT (role = 'admin') INTO v_is_real_admin
    FROM public.profiles
    WHERE id = v_caller_id;

    SELECT author_id, deleted_by_user, deleted_by_admin, handling_status
    INTO v_author_id, v_deleted_user, v_deleted_admin, v_status
    FROM public.reports
    WHERE id = p_report_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Laporan tidak ditemukan.';
    END IF;

    -- Validasi hak penghapusan
    IF p_is_admin THEN
        IF NOT COALESCE(v_is_real_admin, false) THEN
            RAISE EXCEPTION 'Akses ditolak: hanya petugas/admin yang dapat melakukan aksi ini.';
        END IF;
        v_deleted_admin := TRUE;
    ELSE
        IF v_author_id != v_caller_id::text THEN
            RAISE EXCEPTION 'Akses ditolak: Anda bukan pemilik laporan ini.';
        END IF;
        v_deleted_user := TRUE;
    END IF;

    -- Cek apakah kedua belah pihak sudah mengonfirmasi penghapusan
    IF v_deleted_user = TRUE AND v_deleted_admin = TRUE THEN
        DELETE FROM public.reports WHERE id = p_report_id;
        v_is_permanently_deleted := TRUE;
    ELSE
        UPDATE public.reports
        SET 
            deleted_by_user = v_deleted_user,
            deleted_by_user_at = CASE WHEN v_deleted_user AND deleted_by_user_at IS NULL THEN now() ELSE deleted_by_user_at END,
            deleted_by_admin = v_deleted_admin,
            deleted_by_admin_at = CASE WHEN v_deleted_admin AND deleted_by_admin_at IS NULL THEN now() ELSE deleted_by_admin_at END,
            deleted_at = COALESCE(deleted_at, now()),
            updated_at = timezone('utc'::text, now())
        WHERE id = p_report_id;
    END IF;

    RETURN jsonb_build_object(
        'report_id', p_report_id,
        'deleted_by_user', v_deleted_user,
        'deleted_by_admin', v_deleted_admin,
        'is_permanently_deleted', v_is_permanently_deleted
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.execute_dual_party_deletion(TEXT, BOOLEAN) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.execute_dual_party_deletion(TEXT, BOOLEAN) FROM anon;

-- RPC: Mark all notifications read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_count INT;
BEGIN
    v_user_id := (SELECT auth.uid());
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;

    UPDATE public.notifications
    SET is_read = TRUE
    WHERE user_id = v_user_id AND is_read = FALSE;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.mark_all_notifications_read() FROM anon;

-- RPC: Upsert device token
CREATE OR REPLACE FUNCTION public.upsert_device_token(
    p_token TEXT,
    p_platform TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := (SELECT auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Autentikasi diperlukan.';
    END IF;

    INSERT INTO public.device_tokens (user_id, token, platform, updated_at)
    VALUES (v_user_id, p_token, p_platform, now())
    ON CONFLICT (token) DO UPDATE
    SET user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        updated_at = now();
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_device_token(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.upsert_device_token(TEXT, TEXT) FROM anon;

-- RPC: Delete device token
CREATE OR REPLACE FUNCTION public.delete_device_token(p_token TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    DELETE FROM public.device_tokens
    WHERE token = p_token AND (user_id = (SELECT auth.uid()) OR (SELECT auth.uid()) IS NULL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_device_token(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_device_token(TEXT) FROM anon;

-- ------------------------------------------------------------------------------
-- 8. GEOSPATIAL RPC FUNCTIONS FOR ALL INDONESIA EXPANSION
-- ------------------------------------------------------------------------------

-- Spatial RPC: Validasi apakah titik koordinat berada di dalam wilayah administratif tertentu
CREATE OR REPLACE FUNCTION public.validate_report_location(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = public, pg_temp
AS $$
DECLARE
    v_point GEOMETRY;
    v_region RECORD;
BEGIN
    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);

    -- Cari wilayah administrasi yang melingkupi titik koordinat
    SELECT id, code, name, level INTO v_region
    FROM public.administrative_regions
    WHERE boundary IS NOT NULL AND ST_Covers(boundary, v_point)
    ORDER BY level = 'village' DESC, level = 'district' DESC, level = 'regency' DESC, level = 'province' DESC
    LIMIT 1;

    IF v_region.id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'is_valid', true,
            'region_id', v_region.id,
            'region_code', v_region.code,
            'region_name', v_region.name,
            'region_level', v_region.level
        );
    END IF;

    RETURN jsonb_build_object(
        'is_valid', false,
        'message', 'Titik koordinat berada di luar cakupan batas wilayah administratif terverifikasi.'
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_report_location(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, anon;

-- Spatial RPC: Resolve Administrative Region Hierarchy from Lat/Lng
CREATE OR REPLACE FUNCTION public.resolve_report_region(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = public, pg_temp
AS $$
DECLARE
    v_point GEOMETRY;
    v_geog GEOGRAPHY;
    v_prov RECORD;
    v_city RECORD;
BEGIN
    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
    v_geog := v_point::geography;

    -- 1. Cari provinsi yang melingkupi titik
    SELECT id, code, name INTO v_prov
    FROM public.administrative_regions
    WHERE level = 'province' AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
    LIMIT 1;

    -- 2. Cari kota/kabupaten berdasar poligon batas, atau fallback ke titik pusat terdekat
    IF v_prov.id IS NOT NULL THEN
        SELECT id, code, name INTO v_city
        FROM public.administrative_regions
        WHERE level = 'regency' AND parent_id = v_prov.id AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
        LIMIT 1;

        IF v_city.id IS NULL THEN
            SELECT id, code, name INTO v_city
            FROM public.administrative_regions
            WHERE level = 'regency' AND parent_id = v_prov.id AND center_point IS NOT NULL
            ORDER BY ST_Distance(center_point, v_geog) ASC
            LIMIT 1;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'province_id', v_prov.id,
        'province_code', v_prov.code,
        'province_name', v_prov.name,
        'city_id', v_city.id,
        'city_code', v_city.code,
        'city_name', v_city.name
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.resolve_report_region(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, anon;

-- Spatial RPC: Get Nearby Feed using PostGIS ST_DWithin and ST_Distance
CREATE OR REPLACE FUNCTION public.get_nearby_feed(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION DEFAULT 5000,
    p_limit INT DEFAULT 20
)
RETURNS SETOF public.reports
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
    SELECT r.*
    FROM public.reports r
    WHERE 
        r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.is_draft = FALSE
        AND r.publication_state = 'published'
        AND r.handling_status NOT IN ('rejected', 'cancelled')
        AND r.location IS NOT NULL
        AND ST_DWithin(
            r.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
            p_radius_meters
        )
    ORDER BY 
        ST_Distance(
            r.location,
            ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
        ) ASC,
        r.created_at DESC
    LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_feed(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INT) TO authenticated, anon;

-- Spatial RPC: Get Regional Feed
CREATE OR REPLACE FUNCTION public.get_regional_feed(
    p_region_id UUID,
    p_limit INT DEFAULT 20
)
RETURNS SETOF public.reports
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
    SELECT r.*
    FROM public.reports r
    WHERE 
        r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.is_draft = FALSE
        AND r.publication_state = 'published'
        AND r.handling_status NOT IN ('rejected', 'cancelled')
        AND (
            r.province_id = p_region_id
            OR r.city_id = p_region_id
            OR r.district_id = p_region_id
            OR r.village_id = p_region_id
        )
    ORDER BY r.created_at DESC
    LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.get_regional_feed(UUID, INT) TO authenticated, anon;

-- ------------------------------------------------------------------------------
-- 9. NOTIFICATION TRIGGERS (SECURED INTERNAL EXECUTION)
-- ------------------------------------------------------------------------------
-- Update comments count trigger
CREATE OR REPLACE FUNCTION public.update_report_comments_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.reports
        SET comments_count = comments_count + 1,
            updated_at = timezone('utc'::text, now())
        WHERE id = NEW.report_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.reports
        SET comments_count = GREATEST(0, comments_count - 1),
            updated_at = timezone('utc'::text, now())
        WHERE id = OLD.report_id;
    END IF;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_comments_count ON public.comments;
CREATE TRIGGER trg_comments_count
    AFTER INSERT OR DELETE ON public.comments
    FOR EACH ROW EXECUTE FUNCTION public.update_report_comments_count();

REVOKE EXECUTE ON FUNCTION public.update_report_comments_count() FROM PUBLIC, anon, authenticated;

-- Report Status Changed Notification Trigger
CREATE OR REPLACE FUNCTION public.trg_report_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
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

        -- Label ramah warga
        v_report_num := COALESCE(NEW.report_number, substring(NEW.id::text from 1 for 8));
        CASE NEW.handling_status
            WHEN 'accepted' THEN
                v_status_label := 'Diterima';
                v_msg := 'Laporan #' || v_report_num || ' telah diterima dan masuk dalam jadwal penanganan petugas.';
            WHEN 'in_progress' THEN
                v_status_label := 'Diproses';
                v_msg := 'Petugas sedang menindaklanjuti laporan #' || v_report_num || ' di lokasi kejadian.';
            WHEN 'completed' THEN
                v_status_label := 'Selesai';
                v_msg := 'Penanganan laporan #' || v_report_num || ' telah selesai. Terima kasih atas partisipasi Anda!';
            WHEN 'rejected' THEN
                v_status_label := 'Ditolak';
                v_msg := 'Laporan #' || v_report_num || ' tidak dapat diproses: ' || COALESCE(NEW.rejection_reason, 'Tidak memenuhi kriteria.');
            WHEN 'cancelled' THEN
                v_status_label := 'Dibatalkan';
                v_msg := 'Laporan #' || v_report_num || ' telah dibatalkan.';
            ELSE
                v_status_label := 'Status Baru';
                v_msg := 'Status laporan #' || v_report_num || ' diperbarui menjadi ' || NEW.handling_status || '.';
        END CASE;

        -- Insert ke inbox in-app notifikasi jika author_id valid UUID
        IF NEW.author_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
            INSERT INTO public.notifications (user_id, title, message, type, report_id)
            VALUES (
                NEW.author_id::UUID,
                'Status Laporan ' || v_status_label,
                v_msg,
                'status_changed',
                NEW.id
            );
        END IF;

    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_report_status_changed ON public.reports;
CREATE TRIGGER trg_notify_report_status_changed
    AFTER UPDATE OF handling_status ON public.reports
    FOR EACH ROW EXECUTE FUNCTION public.trg_report_status_notification();

REVOKE EXECUTE ON FUNCTION public.trg_report_status_notification() FROM PUBLIC, anon, authenticated;

-- Announcement Notification Trigger
CREATE OR REPLACE FUNCTION public.trg_announcement_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    IF (TG_OP = 'INSERT' AND NEW.is_published = TRUE) OR
       (TG_OP = 'UPDATE' AND OLD.is_published = FALSE AND NEW.is_published = TRUE) THEN
        INSERT INTO public.notification_queue (event_type, payload)
        VALUES (
            'announcement_broadcast',
            jsonb_build_object(
                'announcement_id', NEW.id,
                'title', NEW.title,
                'content', substring(NEW.content from 1 for 150),
                'category', NEW.category,
                'author_name', NEW.author_name
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_announcement ON public.announcements;
CREATE TRIGGER trg_notify_announcement
    AFTER INSERT OR UPDATE OF is_published ON public.announcements
    FOR EACH ROW EXECUTE FUNCTION public.trg_announcement_notification();

REVOKE EXECUTE ON FUNCTION public.trg_announcement_notification() FROM PUBLIC, anon, authenticated;

COMMIT;
