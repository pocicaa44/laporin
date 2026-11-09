# Laporin — Database Migrations Guide

Dokumen ini mendokumentasikan urutan, isi, dan tata cara eksekusi migrasi basis data untuk proyek **Laporin**.

---

## 1. Urutan Berkas Migrasi Resmi

Seluruh berkas migrasi tersimpan pada direktori [`supabase/migrations/`](file:///d:/project_dewanto/flutter_app/laporin/supabase/migrations):

| No | Nama Berkas Migrasi | Domain & Tanggung Jawab |
| :---: | :--- | :--- |
| **01** | `20261022000000_create_votes_table_and_rpc.sql` | Baseline tabel `votes` & prosedur voting atomik |
| **02** | `20261023000000_create_comments_table_and_triggers.sql` | Baseline tabel `comments` & trigger agregat komentar |
| **03** | `20261024000000_add_soft_delete_and_reports_rls.sql` | Kebijakan soft-delete & RLS laporan awal |
| **04** | `20261024010000_create_avatars_storage_bucket.sql` | Konfigurasi bucket Storage `avatars` & RLS media |
| **05** | `20261024020000_add_author_profile_columns_and_sync_trigger.sql` | Sinkronisasi metadata profil penulis ke laporan |
| **06** | `20261024030000_admin_role_and_announcements.sql` | Peran admin, tabel `announcements`, dan RLS pengumuman |
| **07** | `20261024040000_add_completion_notes_to_reports.sql` | Kolom `completion_notes` bukti penanganan petugas |
| **08** | `20261024050000_add_is_discussion_active_to_reports.sql` | Kolom `is_discussion_active` kontrol diskusi laporan |
| **09** | `20261024060000_add_image_url_to_announcements.sql` | Kolom `image_url` banner pengumuman |
| **10** | `20261024070000_add_is_draft_to_reports.sql` | Kolom `is_draft` dan dukungan alur draf laporan warga |
| **11** | `20261025081000_sync_google_avatar_to_reports.sql` | Sinkronisasi foto profil Google login |
| **12** | `20261025090000_add_dual_party_report_deletion.sql` | Skema penghapusan dua pihak (*Dual-Party Deletion*) |
| **13** | `20261025185300_enable_realtime_for_announcements.sql` | Publikasi Realtime Supabase untuk pengumuman |
| **14** | `20261026000000_create_device_tokens_and_notification_triggers.sql` | Registrasi perangkat FCM & antrean notifikasi |
| **15** | `20261026010000_create_notifications_table.sql` | Tabel kotak masuk notifikasi in-app pengguna |
| **16** | `20261026020000_update_notification_templates_and_triggers.sql` | Format pesan status laporan & trigger notifikasi |
| **17** | `20261026030000_fix_report_status_trigger_uuid_cast.sql` | Perbaikan pengecekan tipe UUID pada trigger notifikasi |
| **18** | `20261026040000_add_mark_all_notifications_read_rpc.sql` | Prosedur RPC tandai semua notifikasi dibaca |
| **19** | `20261109000000_refactor_and_geospatial_architecture.sql` | **Master Refactoring & Geospatial Architecture**: PostGIS spatial tables, Indonesian administrative regions, spatial GiST indexing, `(SELECT auth.uid())` RLS initplan optimizations, dan pengerasan fungsi. |
| **20** | `20261109000001_seed_indonesia_administrative_regions.sql` | **Seed Data Nasional**: 1 Negara, seluruh 38 provinsi di Indonesia, 35 kabupaten/kota Jawa Tengah, dan poligon batas resmi Provinsi Jawa Tengah. |
| **21** | `20261109000002_performance_and_security_polishing.sql` | **Polish Indeks & RLS**: Indeks foreign key penutup (`district_id`, `village_id`), eliminasi kebijakan ganda permisif, dan pembersihan constraint duplikat. |

---

## 2. Cara Menjalankan Migrasi ke Lingkungan Supabase

### A. Menggunakan Supabase CLI (Rekomendasi Utama)

Pastikan CLI terhubung ke proyek Supabase:
```bash
npx supabase link --project-ref ecgnhfkzvivddgbbfajx
```

Eksekusi berkas migrasi menggunakan perintah query terhubung:
```bash
npx supabase db query --linked -f "supabase/migrations/20261109000000_refactor_and_geospatial_architecture.sql"
npx supabase db query --linked -f "supabase/migrations/20261109000001_seed_indonesia_administrative_regions.sql"
npx supabase db query --linked -f "supabase/migrations/20261109000002_performance_and_security_polishing.sql"
```

### B. Sinkronisasi Status Migrasi (`schema_migrations`)

Catat versi migrasi ke tabel histori sistem:
```sql
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES 
    ('20261109000000', 'refactor_and_geospatial_architecture'),
    ('20261109000001', 'seed_indonesia_administrative_regions'),
    ('20261109000002', 'performance_and_security_polishing')
ON CONFLICT (version) DO NOTHING;
```

