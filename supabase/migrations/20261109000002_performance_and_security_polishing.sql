-- ==============================================================================
-- LAPORIN PERFORMANCE & SECURITY POLISHING
-- Migration: 20261109000002_performance_and_security_polishing.sql
-- ==============================================================================

BEGIN;

-- 1. Indexing covering foreign keys to eliminate unindexed_foreign_keys warnings
CREATE INDEX IF NOT EXISTS idx_reports_district_id ON public.reports(district_id);
CREATE INDEX IF NOT EXISTS idx_reports_village_id ON public.reports(village_id);

-- 2. Drop duplicate constraint on votes
ALTER TABLE public.votes DROP CONSTRAINT IF EXISTS uq_votes_report_user;

-- 3. Drop legacy redundant permissive policies to eliminate multiple_permissive_policies warnings
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Allow reading votes" ON public.votes;

-- 4. Scope administrative_regions admin policy to mutative actions (INSERT, UPDATE, DELETE)
-- so it does not overlap with the SELECT policy
DROP POLICY IF EXISTS "Admins can manage administrative regions" ON public.administrative_regions;

CREATE POLICY "Admins can insert administrative regions"
ON public.administrative_regions FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

CREATE POLICY "Admins can update administrative regions"
ON public.administrative_regions FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

CREATE POLICY "Admins can delete administrative regions"
ON public.administrative_regions FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = (SELECT auth.uid()) AND p.role = 'admin'
    )
);

COMMIT;
