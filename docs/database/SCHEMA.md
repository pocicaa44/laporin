# Laporin — Database Schema Specification

Dokumen ini merupakan katalog teknis spesifikasi skema basis data PostgreSQL untuk **Laporin**.

---

## 1. Daftar Tabel

### 1.1 `public.administrative_regions`
Tabel referensi spasial hierarki administratif wilayah Republik Indonesia.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `code` | `VARCHAR(20)` | NO | — | Unique, Kode resmi BPS/Kemendagri (e.g. 'ID', '33', '33.74') |
| `name` | `VARCHAR(150)`| NO | — | Nama resmi wilayah |
| `level` | `VARCHAR(20)` | NO | — | `CHECK (level IN ('country', 'province', 'regency', 'district', 'village'))` |
| `parent_id`| `UUID` | YES | `NULL` | Foreign key $\rightarrow$ `administrative_regions(id)` ON DELETE RESTRICT |
| `boundary` | `GEOMETRY(MultiPolygon, 4326)` | YES | `NULL` | Batas wilayah spasial (PostGIS) |
| `center_point` | `GEOGRAPHY(Point, 4326)` | YES | `NULL` | Titik koordinat pusat wilayah |
| `source` | `VARCHAR(100)`| YES | `'KEMENDAGRI/BPS'` | Sumber data resmi |
| `boundary_status` | `VARCHAR(30)` | YES | `'verified'` | Status validitas geometri poligon |
| `created_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu pencatatan |
| `updated_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu modifikasi |

**Indeks:**
* `idx_admin_regions_boundary`: GiST index pada kolom `boundary` untuk kueri spasial point-in-polygon (`ST_Covers`).
* `idx_admin_regions_center`: GiST index pada `center_point`.
* `idx_admin_regions_parent`: B-Tree index pada `parent_id`.
* `idx_admin_regions_level`: B-Tree index pada `level`.
* `idx_admin_regions_code`: B-Tree index pada `code`.

---

### 1.2 `public.profiles`
Tabel profil pengguna aplikasi warga dan petugas/admin yang tersinkronisasi dengan Supabase Auth.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | — | Primary Key $\rightarrow$ `auth.users(id)` ON DELETE CASCADE |
| `username` | `TEXT` | YES | — | Unique, handle warga (`@username`) |
| `full_name`| `TEXT` | NO | `'Warga Laporin'` | Nama lengkap pengguna |
| `avatar_url`| `TEXT` | YES | `NULL` | URL foto profil dari Supabase Storage `avatars` |
| `role` | `TEXT` | NO | `'user'` | `CHECK (role IN ('user', 'admin'))` |
| `assigned_area_ids` | `TEXT[]` | YES | `'{}'::text[]` | Daftar ID wilayah penugasan petugas |
| `created_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu registrasi |
| `updated_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu modifikasi |

**Indeks:**
* `idx_profiles_username`: B-Tree index untuk pencarian keunikan username.
* `idx_profiles_role`: B-Tree index untuk filtering peran.

---

### 1.3 `public.reports`
Tabel utama penyimpan laporan masalah fasilitas publik dan lingkungan.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | NO | `gen_random_uuid()::text`| Primary Key (kompatibel format 'rep-...' dan UUID) |
| `report_number` | `VARCHAR(50)` | NO | — | Unique nomor tiket (e.g. `LPR-2026-0001`) |
| `author_id` | `TEXT` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `author_name` | `TEXT` | NO | — | Snapshot nama pelapor |
| `author_username` | `TEXT` | YES | `NULL` | Snapshot username pelapor |
| `author_avatar_url` | `TEXT` | YES | `NULL` | Snapshot foto profil pelapor |
| `title` | `TEXT` | NO | — | Judul laporan |
| `description` | `TEXT` | NO | — | Deskripsi lengkap kejadian |
| `category` | `TEXT` | NO | — | Kategori infrastruktur/lingkungan |
| `latitude` | `DOUBLE PRECISION`| NO | — | Garis lintang WGS 84 desimal |
| `longitude` | `DOUBLE PRECISION`| NO | — | Garis bujur WGS 84 desimal |
| `location` | `GEOGRAPHY(Point, 4326)` | YES | `NULL` | Titik spasial PostGIS (disinkronisasi trigger) |
| `location_address` | `TEXT` | NO | — | Alamat hasil reverse-geocoding |
| `province_id` | `UUID` | YES | `NULL` | Foreign key $\rightarrow$ `administrative_regions(id)` ON DELETE SET NULL |
| `city_id` | `UUID` | YES | `NULL` | Foreign key $\rightarrow$ `administrative_regions(id)` ON DELETE SET NULL |
| `district_id` | `UUID` | YES | `NULL` | Foreign key $\rightarrow$ `administrative_regions(id)` ON DELETE SET NULL |
| `village_id` | `UUID` | YES | `NULL` | Foreign key $\rightarrow$ `administrative_regions(id)` ON DELETE SET NULL |
| `area_id` | `TEXT` | YES | `'area-jateng'` | ID area pelaporan |
| `area_name` | `TEXT` | YES | `'Jawa Tengah'` | Nama area pelaporan |
| `handling_status` | `TEXT` | NO | `'new'` | `CHECK (handling_status IN ('new', 'accepted', 'in_progress', 'completed', 'rejected', 'cancelled'))` |
| `publication_state` | `TEXT` | NO | `'published'` | `CHECK (publication_state IN ('pending_review', 'published', 'held', 'archived'))` |
| `photo_urls` | `TEXT[]` | NO | `'{}'::text[]` | Daftar URL foto bukti (maksimal 5) |
| `upvotes_count` | `INTEGER` | NO | `0` | Agregat jumlah vote positif |
| `downvotes_count` | `INTEGER` | NO | `0` | Agregat jumlah vote negatif |
| `comments_count` | `INTEGER` | NO | `0` | Agregat jumlah komentar aktif |
| `rejection_reason` | `TEXT` | YES | `NULL` | Alasan penolakan jika status `rejected` |
| `moderation_reason` | `TEXT` | YES | `NULL` | Alasan penahanan jika status `held` |
| `completion_proof_url` | `TEXT` | YES | `NULL` | URL foto bukti selesai dari petugas |
| `completion_proof_type` | `TEXT` | YES | `NULL` | Format lampiran bukti (`image`) |
| `completion_notes` | `TEXT` | YES | `NULL` | Uraian penanganan pekerjaan petugas |
| `is_discussion_active` | `BOOLEAN` | NO | `true` | Toggle diskusi aktif |
| `is_draft` | `BOOLEAN` | NO | `false` | Penanda draf laporan warga |
| `deleted_by_user` | `BOOLEAN` | NO | `false` | Penanda penghapusan oleh pelapor |
| `deleted_by_user_at` | `TIMESTAMPTZ` | YES | `NULL` | Waktu penghapusan pelapor |
| `deleted_by_admin` | `BOOLEAN` | NO | `false` | Penanda penghapusan oleh admin |
| `deleted_by_admin_at` | `TIMESTAMPTZ` | YES | `NULL` | Waktu penghapusan admin |
| `published_at` | `TIMESTAMPTZ` | YES | `NULL` | Waktu rilis publik |
| `terminal_at` | `TIMESTAMPTZ` | YES | `NULL` | Waktu masuk status terminal |
| `archive_after` | `TIMESTAMPTZ` | YES | `NULL` | Batas waktu auto-arsip (24 jam) |
| `deleted_at` | `TIMESTAMPTZ` | YES | `NULL` | Timestamp soft delete |
| `created_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu dibuat |
| `updated_at` | `TIMESTAMPTZ` | NO | `timezone('utc', now())` | Waktu modifikasi |

**Indeks:**
* `idx_reports_spatial_location`: GiST index pada kolom `location` untuk kueri radius dan geofencing.
* `idx_reports_public_feed`: Partial Composite B-Tree index pada `(publication_state, handling_status, created_at DESC)` memfilter kondisi aktif non-deleted.
* `idx_reports_author_created`: Composite B-Tree pada `(author_id, is_draft, created_at DESC)` untuk layar Laporan Saya.
* `idx_reports_status_created`: B-Tree pada `(handling_status, created_at DESC)` untuk antrean admin.
* `idx_reports_province_id`, `idx_reports_city_id`, `idx_reports_district_id`, `idx_reports_village_id`: Covering foreign key indexes.

---

### 1.4 `public.votes`
Tabel pencatatan upvote dan downvote partisipatif dari warga.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `report_id` | `TEXT` | NO | — | Foreign key $\rightarrow$ `reports(id)` ON DELETE CASCADE |
| `user_id` | `UUID` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `vote_type` | `TEXT` | NO | — | `CHECK (vote_type IN ('up', 'down'))` |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu vote pertama |
| `updated_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu toggle / ubah vote |

**Constraint:**
* `votes_report_user_unique`: `UNIQUE (report_id, user_id)` menjamin tepat 1 vote per akun per laporan.

---

### 1.5 `public.comments`
Tabel komentar dan diskusi publik berjenjang pada thread laporan.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `TEXT` | NO | `gen_random_uuid()::text` | Primary Key |
| `report_id` | `TEXT` | NO | — | Foreign key $\rightarrow$ `reports(id)` ON DELETE CASCADE |
| `author_id` | `TEXT` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `author_name` | `TEXT` | NO | `'Warga'` | Snapshot nama penulis |
| `author_avatar_url` | `TEXT` | YES | `NULL` | Snapshot foto profil |
| `author_role` | `TEXT` | NO | `'user'` | `CHECK (author_role IN ('user', 'admin'))` |
| `body` | `TEXT` | NO | — | `CHECK (char_length(trim(body)) > 0)` |
| `parent_comment_id` | `TEXT` | YES | `NULL` | Foreign key $\rightarrow$ `comments(id)` ON DELETE CASCADE |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu kirim |
| `updated_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu modifikasi |
| `deleted_at` | `TIMESTAMPTZ` | YES | `NULL` | Soft delete komentar |

---

### 1.6 `public.announcements`
Tabel siaran pengumuman resmi dari petugas / admin kepada warga.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `title` | `TEXT` | NO | — | Judul pengumuman |
| `content` | `TEXT` | NO | — | Isi lengkap pengumuman |
| `category` | `TEXT` | NO | `'Umum'` | Kategori pengumuman |
| `author_id` | `UUID` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `author_name` | `TEXT` | NO | — | Nama admin pembuat |
| `image_url` | `TEXT` | YES | `NULL` | URL banner gambar dari Supabase Storage |
| `is_published` | `BOOLEAN` | NO | `true` | Status publikasi |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu publikasi |
| `updated_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu modifikasi |

---

### 1.7 `public.device_tokens`
Tabel pendaftaran token perangkat FCM untuk notifikasi push.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `user_id` | `UUID` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `token` | `TEXT` | NO | — | Unique, token registrasi FCM |
| `platform` | `TEXT` | NO | `'android'` | `CHECK (platform IN ('android', 'ios', 'web'))` |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu register |
| `updated_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu refresh token |

---

### 1.8 `public.notifications`
Kotak masuk notifikasi in-app pengguna.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `user_id` | `UUID` | NO | — | Foreign key $\rightarrow$ `profiles(id)` ON DELETE CASCADE |
| `title` | `TEXT` | NO | — | Judul notifikasi |
| `message` | `TEXT` | NO | — | Isi notifikasi |
| `type` | `TEXT` | NO | `'status_changed'` | Jenis notifikasi |
| `report_id` | `TEXT` | YES | `NULL` | Foreign key $\rightarrow$ `reports(id)` ON DELETE CASCADE |
| `is_read` | `BOOLEAN` | NO | `false` | Penanda sudah dibaca |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu dikirim |

---

### 1.9 `public.notification_queue`
Antrean notifikasi latar belakang untuk FCM Edge Function.

| Kolom | Tipe Data | Nullable | Default | Keterangan & Constraint |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `UUID` | NO | `gen_random_uuid()` | Primary Key |
| `event_type` | `TEXT` | NO | — | Event pemicu (e.g. `report_status_changed`, `broadcast`) |
| `payload` | `JSONB` | NO | — | Payload data notifikasi |
| `status` | `TEXT` | NO | `'pending'` | `CHECK (status IN ('pending', 'processing', 'completed', 'failed'))` |
| `created_at` | `TIMESTAMPTZ` | NO | `now()` | Waktu masuk antrean |
| `processed_at`| `TIMESTAMPTZ`| YES | `NULL` | Waktu eksekusi worker |
| `error_message`| `TEXT` | YES | `NULL` | Log error jika gagal |

---

## 2. Fungsi Stored Procedures & RPC

| Nama Fungsi | Parameter | Keamanan | Deskripsi |
| :--- | :--- | :---: | :--- |
| `is_admin()` | — | `DEFINER` | Memeriksa apakah pemanggil adalah akun admin |
| `vote_report` | `(p_report_id text, p_vote_type text)` | `DEFINER` | Atomic vote toggle & kalkulasi ambang downvote ($\ge 70\%$) |
| `execute_dual_party_deletion` | `(p_report_id text, p_is_admin boolean)` | `DEFINER` | Menandai soft delete per pihak & hard delete permanen jika keduanya setuju |
| `mark_all_notifications_read` | — | `DEFINER` | Menandai seluruh notifikasi pemanggil menjadi telah dibaca |
| `upsert_device_token` | `(p_token text, p_platform text)` | `DEFINER` | Menyimpan token perangkat FCM pengguna |
| `delete_device_token` | `(p_token text)` | `DEFINER` | Menghapus token perangkat saat logout |
| `validate_report_location` | `(p_lat float8, p_lng float8)` | `STABLE` | Memvalidasi titik koordinat dalam wilayah terdaftar (PostGIS) |
| `resolve_report_region` | `(p_lat float8, p_lng float8)` | `STABLE` | Mendeteksi otomatis provinsi & kota/kabupaten koordinat |
| `get_nearby_feed` | `(p_lat float8, p_lng float8, p_radius_meters float8, p_limit int)` | `STABLE` | Kueri laporan publik dalam radius meter terdekat (`ST_DWithin`) |
| `get_regional_feed` | `(p_region_id uuid, p_limit int)` | `STABLE` | Kueri feed laporan berdasarkan wilayah administratif |

