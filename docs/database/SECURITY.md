# Laporin — Database Security & Authorization Specification

Dokumen ini mendefinisikan arsitektur keamanan, kebijakan Row Level Security (RLS), aturan otorisasi peran, dan pengerasan fungsi database **Laporin**.

---

## 1. Temuan Audit Keamanan Database Lama & Solusinya

| Masalah yang Ditemukan | Resiko Keamanan | Solusi & Implementasi Baru |
| :--- | :--- | :--- |
| **Search Path Rentan pada Fungsi** | Fungsi PL/pgSQL tidak menetapkan `search_path`, rentan eksploitasi pembajakan skema (*search_path hijacking*). | Seluruh fungsi dan trigger kini dilengkapi: `SET search_path = public, pg_temp;`. |
| **Trigger Functions Terekspos ke Publik** | Fungsi trigger internal (`trg_*`) dapat dipanggil langsung oleh role `anon` dan `authenticated` melalui PostgREST RPC. | Dijalankan `REVOKE EXECUTE ON FUNCTION ... FROM PUBLIC, anon, authenticated;` pada seluruh fungsi internal/trigger. Hanya trigger mesin database yang berhak memanggil. |
| **Evaluasi RLS Per-Baris Lambat (`auth.uid()`)** | Pemanggilan fungsi `auth.uid()` berulang untuk setiap baris memperlambat kueri dan meningkatkan beban CPU. | Seluruh kebijakan RLS dioptimalkan menggunakan pembungkus subquery `(SELECT auth.uid())` (*InitPlan*), dievaluasi 1x per kueri. |
| **Eskalasi Peran Mandiri Pengguna** | Pengguna dapat mengirim payload update profil dengan `'role': 'admin'`. | Ditambahkan klausa `WITH CHECK` pada policy RLS `profiles`: pengguna hanya dapat mempertahankan perannya atau perubahan hanya diizinkan jika admin. |
| **Ketiadaan Foreign Key pada `reports.author_id`** | Kolom `author_id` berupa `TEXT` tanpa foreign key constraint ke `profiles.id`. | Relasi diikat secara formal dengan `author_id TEXT REFERENCES public.profiles(id) ON DELETE CASCADE`. |

---

## 2. Kebijakan Row Level Security (RLS) per Tabel

### 2.1 `public.profiles`
* **SELECT:** Terbuka untuk `authenticated` dan `anon` (agar nama & avatar pelapor dapat ditampilkan di feed publik).
* **INSERT:** Hanya untuk user yang bersangkutan: `id = (SELECT auth.uid())`.
* **UPDATE:** Hanya user yang bersangkutan: `id = (SELECT auth.uid())`, dan dilarang mengubah kolom `role` menjadi admin kecuali pemanggil sudah berstatus admin.
* **DELETE:** Dilarang untuk client (hanya via cascading `auth.users` atau Supabase Admin).

### 2.2 `public.reports`
* **SELECT:**
  1. Konten Publik Aktif:
     ```sql
     deleted_at IS NULL
     AND deleted_by_user = FALSE
     AND deleted_by_admin = FALSE
     AND is_draft = FALSE
     AND publication_state = 'published'
     AND handling_status NOT IN ('rejected', 'cancelled')
     ```
  2. Pemilik Laporan: Dapat membaca laporannya jika `author_id = (SELECT auth.uid())::text` dan belum dihapus oleh user.
  3. Petugas / Admin: Dapat membaca laporan apa pun yang belum dihapus oleh admin.
* **INSERT:** Pengguna terautentikasi (`author_id = (SELECT auth.uid())::text`). Admin tidak diizinkan membuat laporan publik warga.
* **UPDATE:**
  * Pemilik: hanya dapat memperbarui laporan miliknya yang belum dihapus.
  * Petugas/Admin: dapat memperbarui status penanganan (`handling_status`), status publikasi, catatan penanganan, dan bukti selesai.
* **DELETE:** Hard delete fisik hanya diizinkan jika kedua belah pihak telah mengonfirmasi penghapusan (`deleted_by_user = TRUE AND deleted_by_admin = TRUE`).

### 2.3 `public.votes`
* **SELECT:** Terbuka untuk `authenticated` dan `anon` untuk memantau penghitungan vote publik.
* **INSERT/UPDATE/DELETE:** Dibatasi ketat hanya untuk pemilik vote: `user_id = (SELECT auth.uid())`.
* **Constraint:** Unique constraint `votes_report_user_unique` mencegah kecurangan vote ganda pada level basis data.

### 2.4 `public.comments`
* **SELECT:** Hanya komentar aktif (`deleted_at IS NULL`) pada laporan yang berstatus publik aktif.
* **INSERT:** Pengguna terautentikasi, pada laporan aktif yang mengizinkan diskusi (`is_discussion_active = TRUE`).
* **UPDATE:** Hanya pemilik komentar (`author_id = (SELECT auth.uid())::text`).
* **DELETE:** Pemilik komentar atau akun petugas/admin.

### 2.5 `public.announcements`
* **SELECT:** Terbuka untuk semua (`is_published = TRUE`), atau akun admin.
* **INSERT/UPDATE/DELETE:** Khusus akun dengan peran `role = 'admin'` pada `public.profiles`.

### 2.6 `public.device_tokens` & `public.notifications`
* **ALL:** Dibatasi secara mutlak hanya untuk akun pemilik token/notifikasi (`user_id = (SELECT auth.uid())`). Akses lintas pengguna diblokir total oleh RLS.

### 2.7 `public.administrative_regions`
* **SELECT:** Terbuka untuk semua pengguna (`authenticated` dan `anon`) sebagai data referensi wilayah publik.
* **INSERT/UPDATE/DELETE:** Khusus akun admin.

---

## 3. Catatan Keamanan Khusus: PostGIS `spatial_ref_sys`

Pada PostgreSQL dengan ekstensi PostGIS terpasang, tabel `public.spatial_ref_sys` dibuat secara internal oleh PostGIS dan dimiliki oleh superuser `supabase_admin`. Tabel ini hanya berisi referensi koordinat spasial standar internasional (seperti EPSG 4326/WGS 84).
* Supabase Linter memberikan informasi advisory karena tabel ini tidak mengaktifkan RLS secara default.
* Karena tabel ini adalah tabel kamus koordinat standar bawaan sistem dan dimiliki oleh `supabase_admin`, tabel ini bersifat aman untuk dibaca oleh publik (`read-only`).
* Untuk proyek enterprise yang memerlukan pengamanan total, tabel dapat dipindahkan ke skema terpisah `extensions` saat migrasi database baru dibuat dari awal.

---

## 4. Otorisasi Peran: Warga (`user`) vs Petugas/Admin (`admin`)

| Operasi | Warga (`user`) | Petugas / Admin (`admin`) |
| :--- | :---: | :---: |
| Membaca Feed Publik | Ya | Ya |
| Membuat Laporan Baru | Ya | **Tidak** (Admin tidak membuat laporan warga) |
| Mengedit Laporan Sendiri | Ya (terbatas) | Ya (penuh pada status & bukti) |
| Menghapus Laporan Sendiri | Ya (tahap 1 Dual-Party) | Ya (tahap 1 Dual-Party) |
| Hard Delete Permanen Laporan | Jika disetujui Admin | Jika disetujui Pemilik |
| Memberikan Upvote / Downvote | Ya | Ya |
| Menulis Komentar Diskusi | Ya | Ya |
| Mengubah Status Penanganan Laporan | **Ditolak** | Ya (`accepted`, `in_progress`, `completed`, `rejected`) |
| Mengunggah Bukti Penyelesaian | **Ditolak** | Ya (Wajib untuk `completed`) |
| Mengaktifkan / Menonaktifkan Diskusi | **Ditolak** | Ya |
| Menerbitkan Pengumuman Siaran | **Ditolak** | Ya |

