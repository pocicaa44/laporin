-- ==============================================================================
-- Migrasi Supabase: Tabel Votes, RLS Policies, dan Fungsi RPC Atomik vote_report
-- Sesuai PRD.md Bagian 7.6 & AGENTS.md Invarian 3.1 - 3.4
-- ==============================================================================

-- 1. Tabel votes (atau report_votes)
CREATE TABLE IF NOT EXISTS public.votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id TEXT NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vote_type TEXT NOT NULL CHECK (vote_type IN ('up', 'down')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_votes_report_user UNIQUE (report_id, user_id)
);

-- Indeks untuk pencarian dan aggregasi cepat
CREATE INDEX IF NOT EXISTS idx_votes_report_id ON public.votes(report_id);
CREATE INDEX IF NOT EXISTS idx_votes_user_id ON public.votes(user_id);
CREATE INDEX IF NOT EXISTS idx_votes_report_type ON public.votes(report_id, vote_type);

-- 2. Pastikan kolom agregat dan moderasi tersedia di tabel reports
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'upvotes_count'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN upvotes_count INTEGER NOT NULL DEFAULT 0 CHECK (upvotes_count >= 0);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'downvotes_count'
    ) THEN
        ALTER TABLE public.reports ADD COLUMN downvotes_count INTEGER NOT NULL DEFAULT 0 CHECK (downvotes_count >= 0);
    END IF;
END $$;

-- 3. Row Level Security (RLS) pada tabel votes
ALTER TABLE public.votes ENABLE ROW LEVEL SECURITY;

-- Policy SELECT: Pengguna dapat membaca vote publik / miliknya
DROP POLICY IF EXISTS "Allow reading votes" ON public.votes;
CREATE POLICY "Allow reading votes"
ON public.votes FOR SELECT
TO authenticated, anon
USING (true);

-- Policy INSERT: Pengguna terautentikasi dapat memberi vote miliknya sendiri
DROP POLICY IF EXISTS "Users can insert their own vote" ON public.votes;
CREATE POLICY "Users can insert their own vote"
ON public.votes FOR INSERT
TO authenticated
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM public.reports r
        WHERE r.id = report_id
          AND r.publication_state = 'published'
          AND r.handling_status NOT IN ('rejected', 'cancelled')
    )
);

-- Policy UPDATE: Pengguna terautentikasi dapat mengubah jenis vote miliknya sendiri
DROP POLICY IF EXISTS "Users can update their own vote" ON public.votes;
CREATE POLICY "Users can update their own vote"
ON public.votes FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
        SELECT 1 FROM public.reports r
        WHERE r.id = report_id
          AND r.publication_state = 'published'
          AND r.handling_status NOT IN ('rejected', 'cancelled')
    )
);

-- Policy DELETE: Pengguna terautentikasi dapat membatalkan vote miliknya sendiri
DROP POLICY IF EXISTS "Users can delete their own vote" ON public.votes;
CREATE POLICY "Users can delete their own vote"
ON public.votes FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- 4. Fungsi RPC Atomik: vote_report
-- Menangani toggle, switch, pembatalan vote, agregasi count, dan evaluasi threshold downvote
CREATE OR REPLACE FUNCTION public.vote_report(
    p_report_id TEXT,
    p_vote_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
    v_user_id UUID;
    v_current_vote TEXT;
    v_new_vote TEXT;
    v_up_count INTEGER;
    v_down_count INTEGER;
    v_total_votes INTEGER;
    v_down_percentage NUMERIC;
    v_pub_state TEXT;
    v_handling_status TEXT;
    v_mod_reason TEXT;
    v_now TIMESTAMPTZ := now();
BEGIN
    -- Validasi tipe vote
    IF p_vote_type NOT IN ('up', 'down') THEN
        RAISE EXCEPTION 'Tipe vote tidak valid: harus "up" atau "down"';
    END IF;

    -- Dapatkan user_id dari JWT caller
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Otentikasi diperlukan untuk melakukan voting';
    END IF;

    -- Kunci baris laporan (FOR UPDATE) untuk mencegah race condition konkuren
    SELECT publication_state, handling_status, moderation_reason
    INTO v_pub_state, v_handling_status, v_mod_reason
    FROM public.reports
    WHERE id = p_report_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Laporan dengan ID % tidak ditemukan', p_report_id;
    END IF;

    -- Invarian Produk: Laporan harus publik dan non-terminal
    IF v_pub_state != 'published' OR v_handling_status IN ('rejected', 'cancelled') THEN
        RAISE EXCEPTION 'Laporan tidak dapat menerima interaksi vote';
    END IF;

    -- Ambil status vote aktif user
    SELECT vote_type INTO v_current_vote
    FROM public.votes
    WHERE report_id = p_report_id AND user_id = v_user_id;

    IF v_current_vote = p_vote_type THEN
        -- Kasus A: Toggle Off (Membatalkan vote)
        DELETE FROM public.votes
        WHERE report_id = p_report_id AND user_id = v_user_id;
        v_new_vote := NULL;
    ELSIF v_current_vote IS NOT NULL THEN
        -- Kasus B: Switch Vote (Ganti up <-> down)
        UPDATE public.votes
        SET vote_type = p_vote_type, updated_at = v_now
        WHERE report_id = p_report_id AND user_id = v_user_id;
        v_new_vote := p_vote_type;
    ELSE
        -- Kasus C: Vote Baru
        INSERT INTO public.votes (report_id, user_id, vote_type, created_at, updated_at)
        VALUES (p_report_id, v_user_id, p_vote_type, v_now, v_now);
        v_new_vote := p_vote_type;
    END IF;

    -- Hitung agregat terbaru secara tepat
    SELECT
        COALESCE(COUNT(*) FILTER (WHERE vote_type = 'up'), 0),
        COALESCE(COUNT(*) FILTER (WHERE vote_type = 'down'), 0)
    INTO v_up_count, v_down_count
    FROM public.votes
    WHERE report_id = p_report_id;

    v_total_votes := v_up_count + v_down_count;
    v_down_percentage := CASE WHEN v_total_votes > 0 THEN (v_down_count::NUMERIC / v_total_votes::NUMERIC) * 100.0 ELSE 0.0 END;

    -- Invarian Produk: Evaluasi ambang batas downvote (>= 10 total, >= 6 down, >= 70%)
    IF v_total_votes >= 10 AND v_down_count >= 6 AND v_down_percentage >= 70.0 THEN
        v_pub_state := 'held';
        v_mod_reason := format('Ambang batas downvote tercapai (%s%%). Ditahan untuk review moderasi.', round(v_down_percentage, 1));
    END IF;

    -- Update tabel reports
    UPDATE public.reports
    SET
        upvotes_count = v_up_count,
        downvotes_count = v_down_count,
        publication_state = v_pub_state,
        moderation_reason = COALESCE(v_mod_reason, moderation_reason),
        updated_at = v_now
    WHERE id = p_report_id;

    -- Return payload status
    RETURN jsonb_build_object(
        'report_id', p_report_id,
        'upvotes_count', v_up_count,
        'downvotes_count', v_down_count,
        'current_user_vote', v_new_vote,
        'publication_state', v_pub_state,
        'moderation_reason', v_mod_reason
    );
END;
$$;
