# Laporin — Database Architecture & Engineering Guide

Dokumen ini merupakan panduan resmi arsitektur basis data untuk sistem **Laporin**. Menggunakan **PostgreSQL 17** pada **Supabase**, terintegrasi dengan ekstensi geospasial **PostGIS 3.3**, otentikasi **Supabase Auth**, notifikasi **Firebase Cloud Messaging (FCM)**, dan aplikasi client **Flutter**.

---

## 1. Ikhtisar Arsitektur Basis Data

Arsitektur database Laporin dirancang mengikuti prinsip:
* **Relational Normalization & Referential Integrity:** Relasi antartabel dijaga dengan foreign key ketat, cascade rules yang terukur, dan pencegahan record yatim (*orphan records*).
* **Geospatial Readiness (PostGIS):** Titik lokasi laporan disimpan dalam tipe data `GEOGRAPHY(Point, 4326)`, dan batas wilayah administratif dalam `GEOMETRY(MultiPolygon, 4326)` berindeks spasial GiST.
* **Dual State Machine Separation:** Pemisahan mutlak antara status penanganan internal (`handling_status`) dan status publikasi/moderasi publik (`publication_state`).
* **Secure-by-Default & Least Privilege:** Row Level Security (RLS) diaktifkan pada 100% tabel publik, dengan optimasi query planner `(SELECT auth.uid())` (*InitPlan*).
* **Hardened Stored Procedures:** Seluruh fungsi database menerapkan `SET search_path = public, pg_temp;` dan membatasi izin `EXECUTE` untuk mencegah eksekusi trigger via REST API PostgREST.

---

## 2. Struktur Schema & Domain Utama

```
┌────────────────────────────────────────────────────────────────────────┐
│                      STRUKTUR DOMAIN BASIS DATA                        │
├─────────────────────┬───────────────────────┬──────────────────────────┤
│ 1. Identity & Auth  │ 2. Spatial & Regions  │ 3. Reports & Lifecycle   │
│    profiles         │ administrative_regions│ reports                  │
│    (sync auth.users)│ (Hierarchy & Polygons)│ (Dual State Machine)     │
├─────────────────────┼───────────────────────┼──────────────────────────┤
│ 4. Social & Engage  │ 5. Notifications      │ 6. Public Broadcast      │
│    votes            │ notifications         │ announcements            │
│    comments         │ device_tokens, queue  │                          │
└─────────────────────┴───────────────────────┴──────────────────────────┘
```

1. **Identity & User Management (`profiles`):**
   * Terikat langsung 1-to-1 dengan `auth.users(id)`.
   * Peran (`role`): `user` (Warga) dan `admin` (Petugas/Admin).
   * Dilindungi trigger sehingga pengguna biasa tidak dapat mengangkat dirinya sendiri menjadi admin.

2. **Geospatial & Administrative Regions (`administrative_regions`):**
   * Hierarki 5 tingkat administratif: `country` $\rightarrow$ `province` $\rightarrow$ `regency` $\rightarrow$ `district` $\rightarrow$ `village`.
   * Siap melayani ekspansi dari Jawa Tengah ke seluruh 38 provinsi di Indonesia.
   * Auto-resolution koordinat laporan ke wilayah administratif melalui PostGIS `ST_Covers`.

3. **Report Management (`reports`):**
   * Laporan terverifikasi dengan foto bukti, catatan progres, bukti penyelesaian, dan koordinat GPS.
   * Sinkronisasi otomatis POINT spasial via trigger `trg_reports_sync_location`.
   * Penghapusan dua pihak (*Dual-Party Deletion*): laporan hanya terhapus secara fisik permanen jika admin DAN pemilik laporan telah mengonfirmasi penghapusan.

4. **Social & Moderation Interaction (`votes`, `comments`):**
   * `votes`: Unique constraint per user per laporan (`votes_report_user_unique`), RPC atomik `vote_report` dengan kalkulasi ambang batas downvote $\ge 70\%$ untuk memicu moderasi review otomatis (`held`).
   * `comments`: Diskusi berjenjang (*nested/parent-child*) dengan penutupan otomatis saat laporan selesai, ditolak, atau dibatalkan.

5. **Notifikasi & FCM (`notifications`, `device_tokens`, `notification_queue`):**
   * Inbox notifikasi in-app pengguna.
   * Antrean pengiriman push notification FCM HTTP v1 via Edge Function.

---

## 3. Konvensi Penamaan (Naming Conventions)

* **Nama Tabel:** Huruf kecil jamak (*snake_case*, plural), contoh: `reports`, `profiles`, `comments`, `administrative_regions`.
* **Primary Key:** Kolom `id` bertipe `UUID` (atau `TEXT` berstandar UUID pada `reports`/`comments` untuk kompatibilitas client ID).
* **Foreign Key:** Pola `[nama_tabel_singular]_id`, contoh: `author_id`, `report_id`, `province_id`, `parent_id`.
* **Timestamp:** Menggunakan tipe data `TIMESTAMPTZ` (UTC), kolom standar `created_at` dan `updated_at`.
* **Soft Delete:** Kolom `deleted_at`, `deleted_by_user`, `deleted_by_user_at`, `deleted_by_admin`, `deleted_by_admin_at`.

---

## 4. Indeks & Panduan Navigasi Dokumentasi

* **[ERD.md](file:///d:/project_dewanto/flutter_app/laporin/docs/database/ERD.md):** Diagram Entity-Relationship visual (Mermaid), relasi kardinalitas, dan kunci tabel.
* **[SCHEMA.md](file:///d:/project_dewanto/flutter_app/laporin/docs/database/SCHEMA.md):** Spesifikasi kamus data tabel, kolom, constraint, default values, dan fungsi database.
* **[SECURITY.md](file:///d:/project_dewanto/flutter_app/laporin/docs/database/SECURITY.md):** Kebijakan Row Level Security (RLS), aturan otorisasi peran, dan keamanan fungsi.
* **[GEOSPATIAL.md](file:///d:/project_dewanto/flutter_app/laporin/docs/database/GEOSPATIAL.md):** Arsitektur PostGIS, hierarki wilayah Indonesia, indeks GiST, dan spatial RPC.

