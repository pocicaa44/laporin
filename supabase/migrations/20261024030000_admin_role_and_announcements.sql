-- ==============================================================================
-- Migrasi Supabase: Batasan Role Admin pada Reports & Tabel Pengumuman (Announcements)
-- Sesuai PRD.md Bagian 3.A, 4.3, 7.12, FR-09 & AGENTS.md
-- ==============================================================================

-- 0. Helper Function: is_admin()
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 1. Perbarui policy INSERT pada tabel reports:
-- Admin TIDAK BOLEH membuat laporan baru. Hanya warga (role 'user') yang diizinkan.
DROP POLICY IF EXISTS "Authenticated users can insert reports" ON public.reports;
DROP POLICY IF EXISTS "Citizens can insert reports" ON public.reports;
CREATE POLICY "Citizens can insert reports"
ON public.reports FOR INSERT
TO authenticated
WITH CHECK (
    ((auth.uid())::text = author_id)
    AND NOT public.is_admin()
);

-- 2. Perbarui policy UPDATE pada tabel reports:
-- Pemilik laporan dapat memperbarui laporannya sendiri, dan Admin dapat memperbarui status laporan
DROP POLICY IF EXISTS "Authors can update own reports" ON public.reports;
DROP POLICY IF EXISTS "Authors can update their own active reports" ON public.reports;
DROP POLICY IF EXISTS "Authors or admins can update reports" ON public.reports;
CREATE POLICY "Authors or admins can update reports"
ON public.reports FOR UPDATE
TO authenticated
USING (
    ((auth.uid())::text = author_id)
    OR public.is_admin()
)
WITH CHECK (
    ((auth.uid())::text = author_id)
    OR public.is_admin()
);

-- 3. Perbarui policy SELECT pada tabel reports:
-- Publik dapat melihat laporan published & non-terminal; pemilik dapat melihat miliknya;
-- Admin dapat melihat seluruh laporan untuk kebutuhan Panel & Moderasi
DROP POLICY IF EXISTS "Public visible reports or own reports are viewable" ON public.reports;
DROP POLICY IF EXISTS "Public can read active published reports" ON public.reports;
CREATE POLICY "Public can read active published reports"
ON public.reports FOR SELECT
TO authenticated, anon
USING (
    (
        deleted_at IS NULL
        AND publication_state = 'published'
        AND handling_status NOT IN ('rejected', 'cancelled')
    )
    OR (auth.uid() IS NOT NULL AND author_id = (auth.uid())::text)
    OR public.is_admin()
);

-- 4. Tabel Pengumuman (Announcements)
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Umum',
    author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    author_name TEXT NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created_at ON public.announcements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_published ON public.announcements(is_published);

-- 5. Row Level Security untuk Pengumuman
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read published announcements" ON public.announcements;
CREATE POLICY "Authenticated users can read published announcements"
ON public.announcements FOR SELECT
TO authenticated, anon
USING (is_published = true OR EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin'
));

DROP POLICY IF EXISTS "Admins can insert announcements" ON public.announcements;
CREATE POLICY "Admins can insert announcements"
ON public.announcements FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);

DROP POLICY IF EXISTS "Admins can update announcements" ON public.announcements;
CREATE POLICY "Admins can update announcements"
ON public.announcements FOR UPDATE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);

DROP POLICY IF EXISTS "Admins can delete announcements" ON public.announcements;
CREATE POLICY "Admins can delete announcements"
ON public.announcements FOR DELETE
TO authenticated
USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
);
