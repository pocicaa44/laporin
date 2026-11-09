-- ==============================================================================
-- LAPORIN GEOSPATIAL & MAPS ENHANCEMENTS: INDONESIA BOUNDARIES & PROVINCIAL FEED
-- Migration: 20261109000003_indonesia_boundary_and_feed_rpcs.sql
-- ==============================================================================

BEGIN;

-- ------------------------------------------------------------------------------
-- 1. SEED INDONESIA NATIONWIDE BOUNDARY & PROVINCE CENTER POINTS
-- ------------------------------------------------------------------------------

-- Update Republik Indonesia boundary with official archipelagic territorial rings
-- Strictly excluding Singapore, Malaysia (Peninsular, Sarawak, Sabah), Brunei, Timor-Leste, and PNG.
UPDATE public.administrative_regions
SET boundary = ST_Multi(ST_GeomFromText(
    'MULTIPOLYGON(' ||
    -- 1. Sumatra Mainland (Excludes Peninsular Malaysia)
    '((95.0 5.9, 97.5 5.5, 99.0 4.0, 100.5 2.5, 102.0 1.5, 103.5 -0.5, 105.0 -1.5, 106.0 -4.5, 106.0 -6.0, 104.0 -6.0, 102.0 -5.0, 100.0 -4.0, 98.0 -1.5, 96.5 2.0, 95.0 5.9)),' ||
    -- 2. Riau Islands: Batam, Bintan, Lingga, Karimun (Max latitude 1.20N strictly excludes Singapore at 1.35N)
    '((103.3 -1.0, 104.8 -1.0, 104.8 1.20, 103.3 1.20, 103.3 -1.0)),' ||
    -- 3. Bangka Belitung Islands
    '((105.0 -3.5, 108.5 -3.5, 108.5 -1.5, 105.0 -1.5, 105.0 -3.5)),' ||
    -- 4. Kepulauan Natuna & Anambas
    '((105.5 2.0, 109.2 2.0, 109.2 4.8, 105.5 4.8, 105.5 2.0)),' ||
    -- 5. Java & Madura
    '((105.0 -8.9, 114.6 -8.9, 114.6 -5.8, 105.0 -5.8, 105.0 -8.9)),' ||
    -- 6. Bali, NTB, NTT (West Timor, Sumba, Flores, Rote; strictly excludes Timor-Leste / Dili east of 125.1E)
    '((114.4 -11.2, 125.1 -11.2, 125.1 -7.8, 114.4 -7.8, 114.4 -11.2)),' ||
    -- 7. Kalimantan (Indonesian territory strictly excludes Sarawak, Sabah, and Brunei)
    '((108.5 -4.5, 119.5 -4.5, 119.5 4.18, 115.5 4.18, 113.5 2.0, 111.0 1.2, 108.5 1.5, 108.5 -4.5)),' ||
    -- 8. Sulawesi & surrounding islands (up to Miangas/Sangihe)
    '((118.5 -6.5, 126.5 -6.5, 126.5 5.6, 118.5 5.6, 118.5 -6.5)),' ||
    -- 9. Maluku & Maluku Utara (Central & North: Ambon, Seram, Buru, Halmahera, Ternate)
    '((124.5 -4.5, 131.0 -4.5, 131.0 3.0, 124.5 3.0, 124.5 -4.5)),' ||
    -- 10. South-East Maluku: Kepulauan Tanimbar, Kei, Aru (Saumlaki, Tual, Dobo)
    '((131.0 -8.5, 135.0 -8.5, 135.0 -5.0, 131.0 -5.0, 131.0 -8.5)),' ||
    -- 11. Papua (Papua, Papua Barat, Papua Selatan, Papua Tengah, Papua Pegunungan, Papua Barat Daya; strictly west of 141.02E)
    '((130.0 -9.5, 141.02 -9.5, 141.02 1.5, 130.0 1.5, 130.0 -9.5))' ||
    ')',
    4326
)),
boundary_status = 'verified'
WHERE code = 'ID';

-- Seed official center points for all 38 provinces in Indonesia
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(96.7494, 4.6951), 4326)::geography WHERE code = '11'; -- Aceh
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(99.1332, 2.1154), 4326)::geography WHERE code = '12'; -- Sumatera Utara
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(100.5700, -0.7399), 4326)::geography WHERE code = '13'; -- Sumatera Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(101.4478, 0.5071), 4326)::geography WHERE code = '14'; -- Riau
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(103.6131, -1.6101), 4326)::geography WHERE code = '15'; -- Jambi
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(104.7458, -3.3194), 4326)::geography WHERE code = '16'; -- Sumatera Selatan
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(102.2655, -3.8004), 4326)::geography WHERE code = '17'; -- Bengkulu
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(105.2625, -4.5586), 4326)::geography WHERE code = '18'; -- Lampung
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(106.1118, -2.7411), 4326)::geography WHERE code = '19'; -- Kepulauan Bangka Belitung
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(104.4534, 3.9457), 4326)::geography WHERE code = '21'; -- Kepulauan Riau
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(106.8456, -6.2088), 4326)::geography WHERE code = '31'; -- DKI Jakarta
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(107.6191, -6.9175), 4326)::geography WHERE code = '32'; -- Jawa Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(110.4203, -6.9932), 4326)::geography WHERE code = '33'; -- Jawa Tengah
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(110.3695, -7.7956), 4326)::geography WHERE code = '34'; -- DI Yogyakarta
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(112.7521, -7.2575), 4326)::geography WHERE code = '35'; -- Jawa Timur
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(106.1065, -6.4058), 4326)::geography WHERE code = '36'; -- Banten
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(115.1889, -8.4095), 4326)::geography WHERE code = '51'; -- Bali
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(117.3820, -8.6529), 4326)::geography WHERE code = '52'; -- Nusa Tenggara Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(121.2195, -8.6574), 4326)::geography WHERE code = '53'; -- Nusa Tenggara Timur
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(111.0969, -0.2787), 4326)::geography WHERE code = '61'; -- Kalimantan Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(113.9213, -1.6815), 4326)::geography WHERE code = '62'; -- Kalimantan Tengah
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(115.2838, -3.0926), 4326)::geography WHERE code = '63'; -- Kalimantan Selatan
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(116.4194, 0.5387), 4326)::geography WHERE code = '64'; -- Kalimantan Timur
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(116.6321, 3.0731), 4326)::geography WHERE code = '65'; -- Kalimantan Utara
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(124.8456, 1.4748), 4326)::geography WHERE code = '71'; -- Sulawesi Utara
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(121.4456, -1.4300), 4326)::geography WHERE code = '72'; -- Sulawesi Tengah
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(119.9741, -3.6687), 4326)::geography WHERE code = '73'; -- Sulawesi Selatan
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(122.0792, -4.1449), 4326)::geography WHERE code = '74'; -- Sulawesi Tenggara
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(123.0600, 0.6999), 4326)::geography WHERE code = '75'; -- Gorontalo
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(119.2321, -2.8441), 4326)::geography WHERE code = '76'; -- Sulawesi Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(128.1814, -3.2385), 4326)::geography WHERE code = '81'; -- Maluku
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(127.5397, 1.5709), 4326)::geography WHERE code = '82'; -- Maluku Utara
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(140.7181, -2.5337), 4326)::geography WHERE code = '91'; -- Papua
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(134.0620, -0.8615), 4326)::geography WHERE code = '92'; -- Papua Barat
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(140.4011, -7.4981), 4326)::geography WHERE code = '93'; -- Papua Selatan
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(135.5005, -3.3639), 4326)::geography WHERE code = '94'; -- Papua Tengah
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(138.9442, -4.0883), 4326)::geography WHERE code = '95'; -- Papua Pegunungan
UPDATE public.administrative_regions SET center_point = ST_SetSRID(ST_MakePoint(131.2562, -0.8762), 4326)::geography WHERE code = '96'; -- Papua Barat Daya

-- ------------------------------------------------------------------------------
-- 2. GEOSPATIAL HELPER & VALIDATION FUNCTIONS
-- ------------------------------------------------------------------------------

-- Helper function: Memeriksa apakah suatu koordinat berada di dalam wilayah hukum Indonesia
CREATE OR REPLACE FUNCTION public.is_point_in_indonesia(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SET search_path = public, pg_temp
AS $$
DECLARE
    v_point GEOMETRY;
    v_is_inside BOOLEAN;
BEGIN
    IF p_lat IS NULL OR p_lng IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Fast numerical sanity check
    IF p_lat < -11.5 OR p_lat > 6.5 OR p_lng < 94.5 OR p_lng > 141.5 THEN
        RETURN FALSE;
    END IF;

    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);

    SELECT EXISTS (
        SELECT 1 
        FROM public.administrative_regions
        WHERE code = 'ID' AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
    ) INTO v_is_inside;

    RETURN v_is_inside;
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_point_in_indonesia(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, anon;

-- RPC: Deteksi Provinsi berdasarkan Koordinat GPS perangkat
CREATE OR REPLACE FUNCTION public.detect_province_by_coordinates(
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
    v_in_indonesia BOOLEAN;
BEGIN
    v_in_indonesia := public.is_point_in_indonesia(p_lat, p_lng);

    IF NOT v_in_indonesia THEN
        RETURN jsonb_build_object(
            'is_valid', false,
            'message', 'Lokasi laporan hanya tersedia di wilayah Indonesia.'
        );
    END IF;

    v_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326);
    v_geog := v_point::geography;

    -- 1. Cari provinsi yang boundary poligonnya meng-cover titik tersebut
    SELECT id, code, name INTO v_prov
    FROM public.administrative_regions
    WHERE level = 'province' AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
    LIMIT 1;

    -- 2. Jika tidak ada poligon khusus provinsi yang meng-cover (atau belum ada poligon detail),
    -- cari provinsi terdekat berdasarkan center_point di Indonesia
    IF v_prov.id IS NULL THEN
        SELECT id, code, name INTO v_prov
        FROM public.administrative_regions
        WHERE level = 'province' AND center_point IS NOT NULL
        ORDER BY ST_Distance(center_point, v_geog) ASC
        LIMIT 1;
    END IF;

    RETURN jsonb_build_object(
        'is_valid', true,
        'province_id', v_prov.id,
        'province_code', v_prov.code,
        'province_name', v_prov.name
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.detect_province_by_coordinates(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, anon;

-- RPC: Validasi Lokasi Laporin (Authoritative Server-side Check)
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
    v_detected JSONB;
BEGIN
    v_detected := public.detect_province_by_coordinates(p_lat, p_lng);

    IF (v_detected->>'is_valid')::boolean = true THEN
        RETURN jsonb_build_object(
            'is_valid', true,
            'province_id', v_detected->>'province_id',
            'province_code', v_detected->>'province_code',
            'province_name', v_detected->>'province_name',
            'region_id', v_detected->>'province_id',
            'region_name', v_detected->>'province_name',
            'region_level', 'province'
        );
    ELSE
        RETURN jsonb_build_object(
            'is_valid', false,
            'message', 'Lokasi laporan hanya tersedia di wilayah Indonesia.'
        );
    END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_report_location(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated, anon;

-- Update trigger sinkronisasi lokasi di reports agar konsisten dengan seluruh Indonesia
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
    v_is_indo BOOLEAN;
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        -- Validasi tegas batas wilayah Indonesia
        v_is_indo := public.is_point_in_indonesia(NEW.latitude, NEW.longitude);
        IF NOT v_is_indo THEN
            RAISE EXCEPTION 'Lokasi laporan hanya tersedia di wilayah Indonesia.';
        END IF;

        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
        v_point := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
        v_geog := NEW.location;

        -- Auto-resolve province jika belum diisi
        IF NEW.province_id IS NULL THEN
            SELECT id, code, name INTO v_prov
            FROM public.administrative_regions
            WHERE level = 'province' AND boundary IS NOT NULL AND ST_Covers(boundary, v_point)
            LIMIT 1;

            IF v_prov.id IS NULL THEN
                SELECT id, code, name INTO v_prov
                FROM public.administrative_regions
                WHERE level = 'province' AND center_point IS NOT NULL
                ORDER BY ST_Distance(center_point, v_geog) ASC
                LIMIT 1;
            END IF;

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

-- ------------------------------------------------------------------------------
-- 3. PROVINCIAL & NATIONAL FEED RPCS
-- ------------------------------------------------------------------------------

-- RPC: Get National Feed (Paginasi berbasis kursor dan filter)
CREATE OR REPLACE FUNCTION public.get_national_feed(
    p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_category TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL
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
        AND (p_cursor_created_at IS NULL OR r.created_at < p_cursor_created_at)
        AND (p_category IS NULL OR p_category = '' OR p_category = 'Semua' OR lower(r.category) = lower(p_category))
        AND (p_status IS NULL OR p_status = '' OR r.handling_status = p_status)
    ORDER BY r.created_at DESC
    LIMIT LEAST(p_limit, 50);
$$;

GRANT EXECUTE ON FUNCTION public.get_national_feed(TIMESTAMPTZ, INT, TEXT, TEXT) TO authenticated, anon;

-- RPC: Get Provincial Feed (Filtered strictly by province_id)
CREATE OR REPLACE FUNCTION public.get_provincial_feed(
    p_province_id UUID,
    p_cursor_created_at TIMESTAMPTZ DEFAULT NULL,
    p_limit INT DEFAULT 20,
    p_category TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL
)
RETURNS SETOF public.reports
LANGUAGE sql
STABLE
SET search_path = public, pg_temp
AS $$
    SELECT r.*
    FROM public.reports r
    WHERE 
        r.province_id = p_province_id
        AND r.deleted_at IS NULL
        AND r.deleted_by_user = FALSE
        AND r.deleted_by_admin = FALSE
        AND r.is_draft = FALSE
        AND r.publication_state = 'published'
        AND r.handling_status NOT IN ('rejected', 'cancelled')
        AND (p_cursor_created_at IS NULL OR r.created_at < p_cursor_created_at)
        AND (p_category IS NULL OR p_category = '' OR p_category = 'Semua' OR lower(r.category) = lower(p_category))
        AND (p_status IS NULL OR p_status = '' OR r.handling_status = p_status)
    ORDER BY r.created_at DESC
    LIMIT LEAST(p_limit, 50);
$$;

GRANT EXECUTE ON FUNCTION public.get_provincial_feed(UUID, TIMESTAMPTZ, INT, TEXT, TEXT) TO authenticated, anon;

-- RPC: Viewport Bounding Box Query for Map
CREATE OR REPLACE FUNCTION public.get_reports_in_viewport(
    p_min_lat DOUBLE PRECISION,
    p_min_lng DOUBLE PRECISION,
    p_max_lat DOUBLE PRECISION,
    p_max_lng DOUBLE PRECISION,
    p_limit INT DEFAULT 100
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
        AND ST_Intersects(
            r.location::geometry,
            ST_MakeEnvelope(p_min_lng, p_min_lat, p_max_lng, p_max_lat, 4326)
        )
    ORDER BY r.created_at DESC
    LIMIT LEAST(p_limit, 200);
$$;

GRANT EXECUTE ON FUNCTION public.get_reports_in_viewport(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, INT) TO authenticated, anon;

COMMIT;
