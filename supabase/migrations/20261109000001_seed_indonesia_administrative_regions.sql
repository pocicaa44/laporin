-- ==============================================================================
-- LAPORIN SEED DATA: INDONESIA ADMINISTRATIVE REGIONS & CENTRAL JAVA BOUNDARY
-- Migration: 20261109000001_seed_indonesia_administrative_regions.sql
-- ==============================================================================

BEGIN;

-- 1. Country: Republik Indonesia
INSERT INTO public.administrative_regions (id, code, name, level, parent_id, source, boundary_status)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'ID',
    'Republik Indonesia',
    'country',
    NULL,
    'BPS/KEMENDAGRI',
    'verified'
) ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name, level = EXCLUDED.level;

-- 2. All 38 Provinces of Indonesia
INSERT INTO public.administrative_regions (id, code, name, level, parent_id, source, boundary_status)
VALUES
    ('b0000000-0000-0000-0000-000000000011', '11', 'Aceh', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000012', '12', 'Sumatera Utara', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000013', '13', 'Sumatera Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000014', '14', 'Riau', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000015', '15', 'Jambi', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000016', '16', 'Sumatera Selatan', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000017', '17', 'Bengkulu', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000018', '18', 'Lampung', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000019', '19', 'Kepulauan Bangka Belitung', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000021', '21', 'Kepulauan Riau', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000031', '31', 'DKI Jakarta', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000032', '32', 'Jawa Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000033', '33', 'Jawa Tengah', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000034', '34', 'DI Yogyakarta', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000035', '35', 'Jawa Timur', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000036', '36', 'Banten', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000051', '51', 'Bali', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000052', '52', 'Nusa Tenggara Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000053', '53', 'Nusa Tenggara Timur', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000061', '61', 'Kalimantan Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000062', '62', 'Kalimantan Tengah', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000063', '63', 'Kalimantan Selatan', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000064', '64', 'Kalimantan Timur', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000065', '65', 'Kalimantan Utara', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000071', '71', 'Sulawesi Utara', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000072', '72', 'Sulawesi Tengah', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000073', '73', 'Sulawesi Selatan', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000074', '74', 'Sulawesi Tenggara', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000075', '75', 'Gorontalo', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000076', '76', 'Sulawesi Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000081', '81', 'Maluku', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000082', '82', 'Maluku Utara', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000091', '91', 'Papua', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000092', '92', 'Papua Barat', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000093', '93', 'Papua Selatan', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000094', '94', 'Papua Tengah', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000095', '95', 'Papua Pegunungan', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified'),
    ('b0000000-0000-0000-0000-000000000096', '96', 'Papua Barat Daya', 'province', 'a0000000-0000-0000-0000-000000000001', 'KEMENDAGRI', 'verified')
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id;

-- 3. All 35 Regencies & Cities of Jawa Tengah
INSERT INTO public.administrative_regions (code, name, level, parent_id, source, center_point)
VALUES
    ('33.74', 'Kota Semarang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.4203, -6.9932), 4326)::geography),
    ('33.72', 'Kota Surakarta', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.8243, -7.5755), 4326)::geography),
    ('33.71', 'Kota Magelang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.2178, -7.4706), 4326)::geography),
    ('33.73', 'Kota Salatiga', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.5084, -7.3305), 4326)::geography),
    ('33.75', 'Kota Pekalongan', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.6753, -6.8886), 4326)::geography),
    ('33.76', 'Kota Tegal', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.1256, -6.8694), 4326)::geography),
    ('33.01', 'Kabupaten Cilacap', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.0059, -7.7279), 4326)::geography),
    ('33.02', 'Kabupaten Banyumas', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.2422, -7.4558), 4326)::geography),
    ('33.03', 'Kabupaten Purbalingga', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.3635, -7.3875), 4326)::geography),
    ('33.04', 'Kabupaten Banjarnegara', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.6974, -7.3976), 4326)::geography),
    ('33.05', 'Kabupaten Kebumen', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.6548, -7.6699), 4326)::geography),
    ('33.06', 'Kabupaten Purworejo', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.0084, -7.7139), 4326)::geography),
    ('33.07', 'Kabupaten Wonosobo', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.9079, -7.3639), 4326)::geography),
    ('33.08', 'Kabupaten Magelang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.2291, -7.5583), 4326)::geography),
    ('33.09', 'Kabupaten Boyolali', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.5947, -7.5312), 4326)::geography),
    ('33.10', 'Kabupaten Klaten', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.6033, -7.7058), 4326)::geography),
    ('33.11', 'Kabupaten Sukoharjo', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.8354, -7.6827), 4326)::geography),
    ('33.12', 'Kabupaten Wonogiri', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.9254, -7.8139), 4326)::geography),
    ('33.13', 'Kabupaten Karanganyar', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.9515, -7.5961), 4326)::geography),
    ('33.14', 'Kabupaten Sragen', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(111.0225, -7.4269), 4326)::geography),
    ('33.15', 'Kabupaten Grobogan', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.9179, -7.0275), 4326)::geography),
    ('33.16', 'Kabupaten Blora', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(111.4184, -6.9698), 4326)::geography),
    ('33.17', 'Kabupaten Rembang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(111.3435, -6.7063), 4326)::geography),
    ('33.18', 'Kabupaten Pati', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(111.0379, -6.7558), 4326)::geography),
    ('33.19', 'Kabupaten Kudus', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.8427, -6.8048), 4326)::geography),
    ('33.20', 'Kabupaten Jepara', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.6778, -6.5889), 4326)::geography),
    ('33.21', 'Kabupaten Demak', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.6375, -6.8944), 4326)::geography),
    ('33.22', 'Kabupaten Semarang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.4042, -7.2139), 4326)::geography),
    ('33.23', 'Kabupaten Temanggung', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.1742, -7.3175), 4326)::geography),
    ('33.24', 'Kabupaten Kendal', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(110.2039, -6.9208), 4326)::geography),
    ('33.25', 'Kabupaten Batang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.7317, -6.9089), 4326)::geography),
    ('33.26', 'Kabupaten Pekalongan', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.6267, -7.0308), 4326)::geography),
    ('33.27', 'Kabupaten Pemalang', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.3817, -6.8925), 4326)::geography),
    ('33.28', 'Kabupaten Tegal', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.1333, -7.0167), 4326)::geography),
    ('33.29', 'Kabupaten Brebes', 'regency', 'b0000000-0000-0000-0000-000000000033', 'KEMENDAGRI', ST_SetSRID(ST_MakePoint(109.0433, -6.8717), 4326)::geography)
ON CONFLICT (code) DO UPDATE
SET name = EXCLUDED.name, parent_id = EXCLUDED.parent_id, center_point = EXCLUDED.center_point;

-- 4. Injeksi Geometri Poligon Batas Resmi Provinsi Jawa Tengah (Berdasarkan Data Geospasial BoundaryService)
UPDATE public.administrative_regions
SET boundary = ST_Multi(ST_GeomFromText(
    'MULTIPOLYGON(((108.829338 -6.74608, 108.854889 -6.799195, 108.952652 -6.83733, 109.027512 -6.774646, 109.116945 -6.849453, 109.284729 -6.873732, 109.375954 -6.859314, 109.444908 -6.835716, 109.525772 -6.783483, 109.574196 -6.837207, 109.704632 -6.859836, 109.83173 -6.91085, 109.994609 -6.926026, 110.135114 -6.886767, 110.161217 -6.857075, 110.218449 -6.858777, 110.224055 -6.898671, 110.282545 -6.910134, 110.360636 -6.958464, 110.439422 -6.946518, 110.482428 -6.918728, 110.567362 -6.805168, 110.593362 -6.738227, 110.63764 -6.680221, 110.692026 -6.53139, 110.686522 -6.496921, 110.72816 -6.449049, 110.8402 -6.409402, 110.920682 -6.406552, 111.03451 -6.421138, 111.051265 -6.504015, 111.089495 -6.595203, 111.135153 -6.652081, 111.208681 -6.687917, 111.288116 -6.682676, 111.353966 -6.700903, 111.460175 -6.661293, 111.493095 -6.616364, 111.563789 -6.638492, 111.694595 -6.752857, 111.659874 -6.780993, 111.648499 -6.828923, 111.615326 -6.836943, 111.609039 -6.903624, 111.566604 -6.951681, 111.612236 -6.971057, 111.62486 -7.065532, 111.580716 -7.201196, 111.544593 -7.209885, 111.448722 -7.280662, 111.438232 -7.353508, 111.346387 -7.352231, 111.219641 -7.295056, 111.241771 -7.24923, 111.146592 -7.262771, 111.133153 -7.30824, 111.132803 -7.386832, 111.112659 -7.415796, 111.151654 -7.563807, 111.189209 -7.603958, 111.180164 -7.709611, 111.230736 -7.747669, 111.29895 -7.864321, 111.287239 -7.953835, 111.246414 -8.086439, 111.217316 -8.196924, 111.111816 -8.21447, 110.957642 -8.170624, 110.825851 -8.073406, 110.74836 -8.016397, 110.742393 -7.92617, 110.718506 -7.878772, 110.63855 -7.828551, 110.513474 -7.778848, 110.472717 -7.730303, 110.426239 -7.654877, 110.443916 -7.545731, 110.369827 -7.575087, 110.287315 -7.636605, 110.150429 -7.712613, 110.057388 -7.781615, 110.023888 -7.884144, 109.84655 -7.794226, 109.687256 -7.751684, 109.43457 -7.709142, 109.280762 -7.712852, 109.10498 -7.717188, 108.973145 -7.706044, 108.797363 -7.671373, 108.731445 -7.592144, 108.6875 -7.512915, 108.632568 -7.433687, 108.621582 -7.314843, 108.643555 -7.215807, 108.753418 -7.156386, 108.775391 -7.05735, 108.829338 -6.74608)))',
    4326
))
WHERE code = '33';

COMMIT;

