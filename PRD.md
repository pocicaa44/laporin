# Product Requirements Document (PRD) — Laporin

- **Nama produk:** Laporin
- **Jenis dokumen:** Product Requirements Document (PRD)
- **Versi:** 1.0 (draft)
- **Tanggal:** 20 Oktober 2026
- **Status:** Draft untuk validasi produk dan implementasi
- **Platform:** Flutter (mobile dan web), Supabase, Firebase Cloud Messaging (FCM)

---

## 1. Ringkasan Produk

Laporin adalah aplikasi pelaporan masalah publik dalam cakupan wilayah yang ditentukan, misalnya provinsi atau kabupaten/kota. Pengguna dapat membuat laporan kerusakan atau masalah fasilitas publik, menambahkan lokasi dan foto, memantau status penanganan, serta berdiskusi melalui thread publik. Admin memvalidasi dan memoderasi laporan, memperbarui progres penanganan, menanggapi komentar, dan memublikasikan pengumuman.

Satu laporan menjadi sumber data utama bagi dua pengalaman:
- **Laporan:** halaman untuk pelapor memantau detail dan status laporan miliknya.
- **Thread:** tampilan komunitas untuk melihat, memberi suara, berkomentar, dan mengikuti perkembangan laporan yang dipublikasikan.

Keduanya bukan salinan data terpisah. Informasi laporan, status, lampiran, dan interaksi harus merujuk pada entitas laporan yang sama.

### 1.1 Tujuan Produk

1. Mempermudah warga melaporkan masalah publik dengan informasi yang dapat ditindaklanjuti.
2. Membuat progres penanganan dapat dipantau secara transparan.
3. Memungkinkan komunitas membantu memprioritaskan dan memoderasi laporan.
4. Memberikan alat kerja bagi admin untuk memvalidasi laporan dan mencatat keputusan secara akuntabel.
5. Menjaga integritas data, keamanan akses, dan batas cakupan wilayah.

### 1.2 Prinsip Produk

- **Satu sumber data:** laporan dan thread menggunakan record yang sama.
- **Status penanganan terpisah dari status publikasi:** laporan dapat sedang ditangani, tetapi status tampil publiknya dikelola secara terpisah.
- **Keputusan penting harus terlacak:** penolakan, pembatalan, penahanan, perubahan status, dan pengarsipan dicatat di audit log.
- **Backend adalah sumber otoritas:** validasi peran, wilayah, status, ambang downvote, dan izin mutasi tidak boleh hanya mengandalkan UI.
- **Tidak menghapus bukti secara diam-diam:** menghilangkan laporan dari tampilan publik berbeda dari menghapus data internal.

---

## 2. Ruang Lingkup

### 2.1 Termasuk dalam MVP

- Login menggunakan Google melalui Supabase Auth.
- Profil pengguna dengan peran `user` atau `admin`.
- Pembuatan laporan dengan judul, deskripsi, lokasi, dan lampiran opsional sesuai validasi.
- Validasi bahwa lokasi laporan berada dalam wilayah layanan yang dikonfigurasi.
- Halaman laporan pribadi dan feed thread publik.
- Upvote, downvote, dan komentar pada laporan yang memenuhi syarat.
- Alur review dan moderasi oleh admin.
- Status penanganan laporan dan riwayat perubahan status.
- Lampiran bukti awal dan bukti penyelesaian berupa foto/video.
- Pengumuman admin.
- Notifikasi melalui Firebase Cloud Messaging.
- Pengarsipan tampilan publik 24 jam setelah laporan ditolak atau dibatalkan.
- Audit log untuk aksi penting.
- Row Level Security (RLS) pada tabel yang terekspos melalui Supabase API.

### 2.2 Tidak Termasuk dalam MVP (kecuali diputuskan kemudian)

- Chat pribadi antar pengguna dan admin.
- Pembayaran, donasi, atau hadiah.
- Sistem reputasi atau peringkat pengguna.
- Integrasi otomatis ke sistem tiket instansi pemerintah.
- Penghapusan permanen otomatis berdasarkan jadwal retensi tertentu; periode retensi internal perlu diputuskan.
- Analisis gambar otomatis atau moderasi berbasis AI sebagai prasyarat publikasi.
- Penggunaan downvote sebagai pembatalan otomatis tanpa review manusia.

---

## 3. Pengguna dan Hak Akses

### 3.1 Persona

| Persona | Kebutuhan utama | Kemampuan utama |
|---|---|---|
| Warga/pelapor | Melaporkan masalah dan memantau progres | Membuat laporan, melihat laporan sendiri, mengedit bagian yang diizinkan, memberi suara, berkomentar |
| Anggota komunitas | Menemukan masalah relevan dan membantu memprioritaskan | Melihat thread publik, memberi suara, berkomentar |
| Admin wilayah | Memeriksa laporan dalam wilayah tugasnya | Review, moderasi, memperbarui status dan merespons komentar/laporan |
| Admin pusat | Mengawasi lintas wilayah sesuai penugasan | Akses lintas wilayah yang secara eksplisit diberikan, moderasi, audit dan pengumuman |

### 3.2 Model Peran

- `profiles.role` menggunakan nilai `user` atau `admin`.
- Akun baru mendapat peran `user` secara default.
- Promosi menjadi admin dilakukan melalui proses tepercaya oleh pengelola yang berwenang, bukan melalui aplikasi klien.
- Admin dapat memiliki penugasan satu atau lebih wilayah melalui `admin_area_assignments`.
- Akses admin pusat lintas wilayah harus dinyatakan eksplisit melalui konfigurasi penugasan/izin. Jangan menganggap semua admin otomatis memiliki akses global.
- Perubahan peran dan penugasan admin wajib tercatat dalam audit log.

### 3.3 Matriks Hak Akses Ringkas

| Aksi | Pengunjung/pengguna | Pemilik laporan | Admin berwenang |
|---|---:|---:|---:|
| Melihat laporan publik | Ya | Ya | Ya |
| Melihat laporan sendiri yang tidak publik | Tidak | Ya | Ya, sesuai cakupan |
| Membuat laporan | Ya, setelah autentikasi | Ya | Ya jika diizinkan |
| Mengedit laporan | Tidak | Terbatas | Ya, sesuai cakupan dan aturan |
| Vote/komentar | Jika autentikasi diwajibkan: ya | Ya | Ya, jika tidak ada konflik kebijakan |
| Mengubah status penanganan | Tidak | Tidak | Ya |
| Menolak/membatalkan/menahan laporan | Tidak | Tidak | Ya; threshold hanya memicu review |
| Mengelola penugasan admin | Tidak | Tidak | Hanya pengelola berwenang |
| Membaca audit log | Tidak | Tidak | Sesuai izin audit |

**Catatan keputusan:** PRD ini mengasumsikan vote dan komentar memerlukan autentikasi. Bila interaksi anonim diinginkan, risiko spam dan manipulasi perlu dinilai ulang.

---

## 4. Alur Utama Pengguna

### 4.1 Membuat Laporan

1. Pengguna login.
2. Pengguna mengisi judul, deskripsi, kategori bila kategori diaktifkan, lokasi, dan lampiran opsional.
3. Backend memvalidasi input, kepemilikan lampiran, format/ukuran file, dan koordinat.
4. Backend memvalidasi bahwa titik lokasi berada di dalam area layanan yang dikonfigurasi.
5. Laporan dibuat dengan status penanganan `new`.
6. Sesuai aturan publikasi, laporan valid dapat langsung dipublikasikan atau masuk review awal. Kebijakan dasar yang direkomendasikan adalah **hybrid**: laporan normal yang lolos validasi dipublikasikan, sedangkan laporan yang ditandai berisiko masuk review.
7. Pengguna menerima konfirmasi dan dapat memantau status.

### 4.2 Melihat Thread

1. Pengguna membuka feed thread.
2. Feed hanya menampilkan laporan dengan `publication_state = published` dan status penanganan yang bukan `rejected` atau `cancelled`.
3. Pengguna membuka detail, memberi upvote/downvote, atau berkomentar.
4. Backend memvalidasi ulang status publikasi dan penanganan pada setiap mutasi, bukan hanya saat halaman dibuka.

### 4.3 Review dan Moderasi

1. Laporan yang ditandai untuk review masuk ke antrean moderasi.
2. Admin yang memiliki cakupan wilayah sesuai dapat membuka laporan dan konteksnya.
3. Admin dapat memublikasikan, menahan, menolak, atau membatalkan laporan sesuai state transition yang diizinkan.
4. Penolakan wajib disertai alasan.
5. Pembatalan oleh moderator wajib memiliki alasan/kode keputusan.
6. Setiap keputusan penting menghasilkan catatan riwayat dan audit log.

### 4.4 Ambang Downvote

- Sistem menghitung persentase downvote dari suara aktif:

  `persentase_downvote = downvote_aktif / (upvote_aktif + downvote_aktif) * 100`

- Suara yang sudah dicabut tidak dihitung.
- Setiap pengguna hanya memiliki satu suara aktif per laporan; pengguna dapat mengganti arah suara atau mencabut suara selama laporan masih memenuhi syarat.
- Ambang harus memakai konfigurasi yang dapat diubah tanpa rilis aplikasi.
- Ambang yang disarankan sebagai **nilai awal untuk diuji, bukan keputusan final**:
  - total suara minimum: 10;
  - jumlah downvote minimum: 6;
  - persentase downvote minimum: 70%.
- Ketika semua syarat ambang tercapai, laporan masuk `held` dan dibuatkan item antrean review secara atomik. **Sistem tidak otomatis membatalkan laporan.**
- Admin meninjau konteks dan memutuskan apakah laporan dipublikasikan kembali, tetap ditahan, atau dibatalkan.

### 4.5 Penolakan/Pembatalan dan Jendela 24 Jam

- Ketika laporan menjadi `rejected` atau `cancelled`, laporan langsung hilang dari feed publik, pencarian publik, endpoint detail publik, serta tidak bisa menerima vote atau komentar baru.
- `terminal_at` dicatat saat keputusan final dibuat.
- `archive_after` dihitung sebagai `terminal_at + 24 jam`.
- Setelah waktu tersebut, laporan berstatus publik `archived` untuk tujuan arsip internal dan tidak tampil di pengalaman publik.
- **24 jam adalah aturan pengarsipan tampilan publik, bukan penghapusan permanen record.** Data internal tetap disimpan mengikuti kebijakan retensi yang nantinya disepakati.
- Permintaan detail publik untuk ID laporan yang tidak lagi publik sebaiknya mengembalikan respons generik yang tidak membocorkan alasan atau data privat.

---

## 5. Model Status dan State Machine

Status penanganan dan publikasi adalah dua dimensi terpisah.

### 5.1 Status Penanganan (`handling_status`)

| Status | Makna | Status terminal? |
|---|---|---:|
| `new` | Laporan baru masuk | Tidak |
| `accepted` | Laporan diterima untuk ditangani | Tidak |
| `in_progress` | Penanganan sedang berjalan | Tidak |
| `completed` | Penanganan selesai dan bukti penyelesaian tervalidasi tersedia | Tidak terminal untuk kebutuhan audit; perubahan lanjutan harus lewat aturan khusus |
| `rejected` | Laporan ditolak oleh admin dengan alasan | Ya |
| `cancelled` | Laporan dibatalkan oleh keputusan moderasi/operasional dengan alasan | Ya |

`completed` berarti pekerjaan selesai, tetapi tetap dapat memiliki kebutuhan koreksi administratif melalui tindakan khusus yang diaudit. `rejected` dan `cancelled` adalah hasil terminal dalam alur normal.

### 5.2 Status Publikasi/Moderasi (`publication_state`)

| Status | Makna | Terlihat publik? |
|---|---|---:|
| `pending_review` | Menunggu review awal | Tidak |
| `published` | Ditampilkan di thread publik | Ya, jika status penanganan juga memenuhi syarat |
| `held` | Ditahan sementara untuk review moderasi | Tidak |
| `archived` | Tidak ditampilkan publik; disimpan untuk arsip internal | Tidak |

### 5.3 Transisi yang Diizinkan

| Dari | Ke | Pemicu | Syarat |
|---|---|---|---|
| `new` + `pending_review` | `new` + `published` | Review/aturan auto-publish | Lolos validasi dan kebijakan publikasi |
| `new` + `pending_review` | `new` + `held` | Penanda risiko/review | Alasan tercatat |
| Status aktif + `published` | Status sama + `held` | Ambang downvote atau laporan moderasi | Item antrean dibuat atomik |
| `held` | `published` | Keputusan moderator | Alasan/hasil review tercatat |
| `new` | `accepted` | Admin menerima laporan | Admin berwenang |
| `accepted` | `in_progress` | Admin memulai penanganan | Admin berwenang |
| `in_progress` | `completed` | Admin menyelesaikan | Bukti penyelesaian valid tersedia |
| Status nonterminal | `rejected` | Admin menolak | Alasan wajib |
| Status nonterminal | `cancelled` | Admin membatalkan | Alasan/kode wajib |
| `rejected`/`cancelled` + status publik apa pun | `archived` | Jadwal setelah 24 jam | Record internal tetap dipertahankan |

Transisi harus divalidasi di database atau fungsi backend tepercaya. UI hanya menyembunyikan tombol yang tidak relevan; UI bukan mekanisme keamanan.

### 5.4 Invarian Wajib

1. Jika `handling_status IN ('rejected', 'cancelled')`, maka laporan tidak boleh tampil publik.
2. Jika `publication_state != 'published'`, laporan tidak boleh tampil di feed publik.
3. Vote dan komentar baru hanya dapat dibuat saat laporan berstatus `published` dan belum terminal.
4. Setiap transisi status mencatat aktor, waktu, alasan bila relevan, status sebelum/sesudah, dan request/event ID.
5. Transisi ke `completed` memerlukan lampiran penyelesaian yang valid.
6. Transisi ke `rejected` memerlukan alasan yang tidak kosong.
7. Transisi ke `cancelled` memerlukan alasan/kode keputusan.
8. Status `held` tidak boleh dianggap sebagai keputusan final dan tidak memulai timer 24 jam.
9. Perubahan `rejected`/`cancelled` langsung menghapus laporan dari hasil baca publik, tanpa menunggu proses arsip 24 jam.

---

## 6. Persyaratan Fungsional

### FR-01 — Autentikasi dan Profil
- Pengguna dapat masuk menggunakan Google melalui Supabase Auth.
- Profil dibuat atau disinkronkan setelah autentikasi.
- Peran default adalah `user`.
- Pengguna tidak dapat mengubah `role` atau penugasan admin melalui klien.
- Pemulihan/reset kata sandi melalui OTP hanya disediakan jika alur dan penyedia autentikasi yang dipilih mendukungnya secara aman.

### FR-02 — Pembuatan Laporan
- Pengguna terautentikasi dapat membuat laporan dengan judul, deskripsi, lokasi, dan lampiran opsional.
- Input wajib memiliki validasi panjang, tipe, dan batas ukuran yang ditentukan pada implementasi.
- Backend memastikan lampiran yang direferensikan memang diunggah oleh pengguna yang berwenang.
- Backend memeriksa koordinat di dalam poligon area layanan.
- Kegagalan validasi tidak boleh meninggalkan laporan parsial atau lampiran yatim tanpa proses pembersihan.

### FR-03 — Edit Terbatas
- Pemilik dapat mengedit laporan hanya selama memenuhi aturan kelayakan edit.
- Kebijakan MVP yang disarankan:
  - sebelum publikasi: pemilik boleh mengubah judul, deskripsi, lokasi, dan lampiran;
  - setelah publikasi: pemilik boleh memperbaiki salah ketik atau deskripsi terbatas, tetapi perubahan lokasi dan perubahan substantif perlu review;
  - setelah laporan memiliki interaksi atau mulai ditangani: edit substantif dibatasi atau diarahkan menjadi koreksi yang memerlukan persetujuan admin.
- Kolom status, alasan moderasi, area otorisasi, timestamp terminal, dan metadata audit tidak boleh diedit pemilik.
- Perubahan penting dicatat dalam audit log dan, bila perlu, memicu review ulang.

### FR-04 — Feed dan Detail Publik
- Feed, pencarian, endpoint detail, dan akses lampiran publik menggunakan satu aturan kelayakan publik yang konsisten.
- Laporan hanya publik jika `publication_state = published` dan `handling_status NOT IN ('rejected', 'cancelled')`.
- Cache, indeks pencarian, dan notifikasi harus dibersihkan/dibatasi saat laporan menjadi `held`, `rejected`, `cancelled`, atau `archived`.
- Menebak ID laporan tidak boleh memberi akses ke laporan nonpublik.

### FR-05 — Vote
- Satu pengguna memiliki paling banyak satu vote aktif per laporan.
- Pengguna dapat membuat, mengganti, atau mencabut vote selama laporan masih `published` dan nonterminal.
- Vote tidak boleh ditulis untuk laporan `held`, `pending_review`, `archived`, `rejected`, atau `cancelled`.
- Evaluasi ambang dan transisi ke `held` dilakukan secara atomik untuk menghindari kondisi balapan.
- Upaya vote berulang tidak boleh menggandakan suara.

### FR-06 — Komentar
- Komentar hanya bisa dibuat pada laporan publik yang aktif.
- Komentar baru ditolak setelah laporan menjadi `held`, `rejected`, `cancelled`, atau `archived`.
- Kebijakan edit/hapus komentar harus membedakan soft delete untuk moderasi dan penghapusan permanen sesuai kebijakan retensi.
- Komentar yang dihapus oleh moderasi menyimpan jejak internal yang sesuai dan tidak ditampilkan publik.
- Batas panjang, rate limit, dan perlindungan spam diterapkan di backend.

### FR-07 — Moderasi
- Admin yang berwenang dapat meninjau laporan, menahan, memublikasikan kembali, menolak, atau membatalkan sesuai state machine.
- Penolakan dan pembatalan memerlukan alasan.
- Ambang downvote hanya memicu penahanan dan antrean review.
- Item antrean harus memiliki alasan, waktu dibuat, status penyelesaian, dan admin penanggung jawab jika ditetapkan.
- Penyelesaian item antrean dan perubahan status dilakukan dalam satu transaksi jika terkait.

### FR-08 — Penanganan dan Bukti Penyelesaian
- Admin dapat memperbarui status `new` → `accepted` → `in_progress` → `completed` sesuai transisi yang sah.
- Untuk `completed`, sistem memvalidasi keberadaan setidaknya satu bukti penyelesaian yang sah, misalnya foto atau video.
- Bukti penyelesaian disimpan dengan metadata tipe, MIME type, ukuran, uploader, dan waktu unggah.
- File harus melalui validasi tipe/ukuran dan tidak boleh diakses melalui URL publik permanen bila memuat informasi sensitif.

### FR-09 — Pengumuman
- Admin berwenang dapat membuat, mengedit, menerbitkan, dan mengarsipkan pengumuman.
- Perubahan pengumuman dicatat dalam audit log.
- Pengumuman yang diterbitkan dapat memicu notifikasi sesuai preferensi dan kebijakan frekuensi.

### FR-10 — Notifikasi
- Notifikasi dapat dikirim untuk:
  - aktivitas vote pada laporan pengguna bila kebijakan produk menganggapnya bernilai;
  - komentar baru;
  - perubahan status laporan;
  - keputusan moderasi yang relevan;
  - pengumuman;
  - laporan baru untuk admin sesuai cakupan wilayah.
- Hindari mengirim notifikasi untuk setiap vote jika volumenya menimbulkan spam; pengelompokan atau preferensi pengguna dapat diterapkan.
- Notifikasi bukan sumber kebenaran status; klien harus mengambil status terbaru dari backend.
- Token FCM dikelola aman, dapat diperbarui/dicabut, dan tidak pernah dicatat sebagai rahasia di audit log.

---

## 7. Skema Data Supabase

Skema berikut adalah rancangan logis. Tipe, constraint, fungsi, dan strategi geospasial perlu difinalisasi dalam migrasi SQL.

### 7.1 `profiles`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK, FK ke `auth.users.id` |
| `full_name` | `text` | Nama tampilan |
| `role` | enum/text | `user` default; perubahan dibatasi backend |
| `created_at` | `timestamptz` | Waktu dibuat |
| `updated_at` | `timestamptz` | Waktu diperbarui |

### 7.2 `areas`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `name` | `text` | Nama area |
| `area_type` | `text` | Provinsi/kabupaten/kota/dll. |
| `boundary` | `geometry(MultiPolygon, 4326)` | Poligon batas wilayah |
| `is_active` | `boolean` | Area layanan aktif |
| `created_at` | `timestamptz` | Waktu dibuat |

### 7.3 `admin_area_assignments`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `admin_id` | `uuid` | FK ke `profiles.id` |
| `area_id` | `uuid` | FK ke `areas.id` |
| `is_primary` | `boolean` | Penugasan utama opsional |
| `created_by` | `uuid` | Pengelola yang memberi penugasan |
| `created_at` | `timestamptz` | Waktu dibuat |

Constraint unik yang disarankan: `(admin_id, area_id)`.

### 7.4 `reports`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_number` | `text` | Nomor laporan publik yang unik |
| `author_id` | `uuid` | FK ke `profiles.id` |
| `area_id` | `uuid` | FK ke `areas.id` |
| `title` | `text` | Judul laporan |
| `description` | `text` | Deskripsi laporan |
| `location` | `geography(Point, 4326)` | Titik lokasi |
| `handling_status` | enum/text | `new`, `accepted`, `in_progress`, `completed`, `rejected`, `cancelled` |
| `publication_state` | enum/text | `pending_review`, `published`, `held`, `archived` |
| `rejection_reason` | `text nullable` | Wajib saat ditolak |
| `moderation_reason` | `text nullable` | Alasan penahanan/moderasi |
| `published_at` | `timestamptz nullable` | Waktu publikasi |
| `terminal_at` | `timestamptz nullable` | Waktu keputusan terminal |
| `archive_after` | `timestamptz nullable` | Biasanya `terminal_at + 24 hours` |
| `created_at` | `timestamptz` | Waktu dibuat |
| `updated_at` | `timestamptz` | Waktu diperbarui |

Constraint/invarian:
- `rejection_reason` wajib jika `handling_status = 'rejected'`.
- `terminal_at` terisi saat status menjadi `rejected` atau `cancelled`.
- `archive_after` diisi sebagai `terminal_at + interval '24 hours'`.
- Status terminal tidak boleh tampil publik, sekalipun `publication_state` keliru tertinggal `published`.
- `area_id` dan `location` harus cocok dengan poligon area yang ditetapkan.
- `report_number` unik.
- Semua mutasi status melalui fungsi backend/database tepercaya.

### 7.5 `report_attachments`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `uploaded_by` | `uuid` | FK ke `profiles.id` |
| `attachment_type` | `text` | `initial_photo`, `completion_photo`, `completion_video` |
| `storage_path` | `text` | Path internal Supabase Storage |
| `mime_type` | `text` | Tipe MIME tervalidasi |
| `file_size_bytes` | `bigint` | Ukuran file |
| `created_at` | `timestamptz` | Waktu unggah |

Jangan mengandalkan ekstensi file saja; validasi MIME/ukuran dan izin akses dilakukan di backend/Storage policies.

### 7.6 `report_votes`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `user_id` | `uuid` | FK ke `profiles.id` |
| `vote_type` | `text` | `up` atau `down` |
| `created_at` | `timestamptz` | Waktu vote pertama/aktif |
| `updated_at` | `timestamptz` | Waktu terakhir diubah |

Constraint unik: `(report_id, user_id)`. Gunakan upsert untuk mengganti arah suara, dan strategi eksplisit untuk mencabut suara (misalnya menghapus record dengan audit event atau menyimpan `revoked_at`).

### 7.7 `report_comments`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `author_id` | `uuid` | FK ke `profiles.id` |
| `parent_comment_id` | `uuid nullable` | FK untuk balasan opsional |
| `body` | `text` | Isi komentar |
| `created_at` | `timestamptz` | Waktu dibuat |
| `updated_at` | `timestamptz` | Waktu diperbarui |
| `deleted_at` | `timestamptz nullable` | Soft delete |

### 7.8 `report_status_history`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `from_status` | `text nullable` | Status sebelumnya |
| `to_status` | `text` | Status berikutnya |
| `actor_id` | `uuid nullable` | Pengguna/admin atau sistem |
| `reason` | `text nullable` | Alasan perubahan |
| `request_id` | `text nullable` | Korelasi request/event |
| `created_at` | `timestamptz` | Waktu perubahan |

Jika dibutuhkan, simpan perubahan `publication_state` pada tabel riwayat terpisah atau tambahkan kolom status publikasi sebelum/sesudah agar dua state machine dapat diaudit dengan jelas.

### 7.9 `moderation_events`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `from_state` | `text nullable` | Status publikasi sebelumnya |
| `to_state` | `text` | Status publikasi berikutnya |
| `trigger_type` | `text` | `downvote_threshold`, `user_flag`, `admin_action`, dll. |
| `reason_code` | `text nullable` | Kode alasan |
| `reason_detail` | `text nullable` | Detail alasan |
| `actor_id` | `uuid nullable` | Admin/pengguna/sistem |
| `vote_snapshot` | `jsonb nullable` | Snapshot jumlah vote dan persentase saat pemicu |
| `created_at` | `timestamptz` | Waktu kejadian |

### 7.10 `report_moderation_queue`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `report_id` | `uuid` | FK ke `reports.id` |
| `queue_reason` | `text` | Alasan masuk antrean |
| `queue_status` | `text` | `open`, `in_review`, `resolved`, `dismissed` |
| `assigned_to` | `uuid nullable` | Admin penanggung jawab |
| `created_at` | `timestamptz` | Waktu dibuat |
| `resolved_at` | `timestamptz nullable` | Waktu selesai |

Cegah antrean duplikat terbuka untuk pemicu yang sama melalui constraint atau fungsi transaksional.

### 7.11 `audit_logs`

| Kolom | Tipe konseptual | Aturan |
|---|---|---|
| `id` | `uuid` | PK |
| `actor_id` | `uuid nullable` | Aktor manusia atau sistem |
| `action` | `text` | Aksi yang dilakukan |
| `entity_type` | `text` | Jenis entitas |
| `entity_id` | `uuid nullable` | ID entitas |
| `old_values` | `jsonb nullable` | Nilai sebelum perubahan yang relevan |
| `new_values` | `jsonb nullable` | Nilai sesudah perubahan yang relevan |
| `reason` | `text nullable` | Alasan |
| `request_id` | `text nullable` | Korelasi request/event |
| `created_at` | `timestamptz` | Waktu kejadian |

Audit log bersifat append-only bagi aplikasi. Hindari menyimpan token, password, atau rahasia. Akses pembacaan audit log dibatasi.

### 7.12 Tabel Tambahan yang Disarankan

- `announcements`: konten, pembuat, status publikasi, jadwal, timestamp.
- `user_devices`: user ID, token FCM, platform, waktu update, waktu pencabutan.
- `notification_outbox`: antrean notifikasi untuk pola transactional outbox/retry.
- `app_config`: konfigurasi ambang downvote, batas upload, dan kebijakan yang dapat diubah tanpa rilis.
- `report_flags`: laporan dari pengguna yang menandai konten bermasalah, bila fitur ini diaktifkan.

---

## 8. RLS dan Keamanan Supabase

**Prinsip utama:** aktifkan RLS pada seluruh tabel yang dapat diakses melalui API. Gunakan fungsi database/RPC atau Edge Functions tepercaya untuk aksi yang membutuhkan validasi lintas tabel dan perubahan state atomik.

### 8.1 Matriks Kebijakan RLS

| Tabel | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `profiles` | Pengguna melihat profil aman sesuai kebutuhan; admin sesuai cakupan | Pembuatan profil melalui trigger/proses tepercaya | Pengguna hanya kolom profil yang diizinkan; `role` tidak dapat diubah pengguna | Tidak tersedia untuk klien |
| `areas` | Area aktif dapat dibaca sesuai kebutuhan aplikasi | Backend/pengelola | Backend/pengelola | Backend/pengelola |
| `admin_area_assignments` | Admin hanya penugasan yang diperlukan; pengelola berwenang | Pengelola berwenang | Pengelola berwenang | Pengelola berwenang |
| `reports` | Publik hanya laporan `published` nonterminal; pemilik laporan miliknya; admin sesuai area | Pengguna terautentikasi melalui validasi backend | Pemilik hanya field yang diizinkan; status melalui fungsi tepercaya | Tidak untuk klien; gunakan arsip/soft delete sesuai kebijakan |
| `report_attachments` | Mengikuti izin parent report dan jenis lampiran | Uploader yang berwenang melalui Storage/API | Terbatas; metadata sensitif tidak bebas diubah | Terbatas; catat penghapusan |
| `report_votes` | Pengguna dapat melihat agregat; detail vote sesuai kebijakan privasi | Vote sendiri pada laporan publik aktif | Vote sendiri pada laporan publik aktif | Pencabutan melalui fungsi yang diaudit |
| `report_comments` | Hanya komentar pada laporan yang boleh dibaca pemohon | Pengguna terautentikasi pada laporan publik aktif | Penulis mengedit komentar sendiri sesuai batas; admin moderasi | Soft delete/aksi tepercaya |
| `report_status_history` | Pemilik dan admin sesuai cakupan; publik hanya jika riwayat memang ditampilkan | Fungsi tepercaya | Tidak diizinkan | Tidak diizinkan |
| `moderation_events` | Moderator/admin yang berwenang | Fungsi tepercaya | Tidak diizinkan | Tidak diizinkan |
| `report_moderation_queue` | Admin/moderator sesuai cakupan | Fungsi tepercaya | Admin berwenang lewat fungsi tepercaya | Tidak untuk klien |
| `audit_logs` | Pengelola/auditor yang berwenang | Fungsi tepercaya | Tidak diizinkan | Tidak diizinkan |

Matriks ini adalah rancangan konseptual, bukan SQL RLS siap produksi. Setiap kebijakan perlu dites dengan akun anonim, pengguna biasa, pemilik laporan, admin beda wilayah, dan admin yang berwenang.

### 8.2 Aturan Keamanan Wajib

1. Jangan menaruh Supabase `service_role` key di aplikasi Flutter/web.
2. Jangan mempercayai `role`, `area_id`, `handling_status`, `publication_state`, `terminal_at`, atau `rejection_reason` dari payload klien.
3. Gunakan database function/Edge Function untuk mutasi status, penentuan wilayah, evaluasi ambang, serta keputusan moderasi.
4. Terapkan pemeriksaan wilayah di backend/database menggunakan geometri batas wilayah, bukan hanya nama lokasi dari perangkat.
5. Storage policies harus mengikuti status dan izin parent report; URL file privat menggunakan akses terotorisasi atau signed URL dengan masa berlaku pendek.
6. Terapkan rate limit pada pembuatan laporan, komentar, vote, dan flag.
7. Validasi ukuran dan tipe file, serta pertimbangkan pemindaian file.
8. Hindari IDOR: mengetahui UUID laporan tidak boleh memberi akses ke laporan privat/nonpublik.
9. Fungsi dengan hak istimewa harus membatasi `search_path`, memeriksa identitas pemanggil, dan meminimalkan hak eksekusi.
10. Uji konsistensi saat dua vote terakhir datang bersamaan agar threshold hanya dievaluasi dan diproses secara benar.

### 8.3 Aturan Kelayakan Publik Terpusat

Buat satu aturan backend yang digunakan konsisten oleh feed, pencarian, detail, komentar, vote, lampiran, cache, dan notifikasi:

- `publication_state = 'published'`
- `handling_status NOT IN ('rejected', 'cancelled')`
- laporan belum diarsipkan/ditahan
- akses lampiran sesuai tipe dan kebijakan privasi

Jangan hanya mengandalkan filter di UI atau view yang bisa dilewati oleh endpoint lain.

---

## 9. Penghapusan, Pengarsipan, dan Retensi

Tiga konsep ini harus dibedakan dengan tegas:

1. **Disembunyikan dari publik:** akses publik dicabut segera karena `held`, `rejected`, `cancelled`, atau `archived`.
2. **Diarsipkan:** laporan tidak tampil dalam pengalaman publik, tetapi data dan jejak audit tetap tersimpan untuk operasional.
3. **Dihapus permanen:** record/file benar-benar dihapus sesuai kebijakan retensi, kebutuhan hukum, dan proses yang terkontrol.

Aturan:
- `rejected` atau `cancelled` langsung tidak dapat dilihat publik dan tidak menerima interaksi.
- Timer 24 jam menentukan kapan status publikasi menjadi `archived`; bukan waktu untuk menunggu sebelum menyembunyikan laporan.
- Data internal, komentar, vote, lampiran, riwayat, dan audit tidak otomatis dihapus setelah 24 jam.
- Tetapkan periode retensi internal terpisah sebelum peluncuran produksi.
- Bila penghapusan permanen diwajibkan, proses harus menghapus/menangani dependensi secara konsisten dan tetap mempertahankan audit minimum yang sah bila kebijakan mengharuskan.
- Jangan mengirim notifikasi yang memuat isi sensitif dari laporan yang sudah tidak publik.

---

## 10. Notifikasi dan Proses Asinkron

### 10.1 Jenis Notifikasi

| Peristiwa | Penerima | Catatan |
|---|---|---|
| Laporan berhasil dibuat | Pelapor | Konfirmasi |
| Laporan diterima/ditolak | Pelapor | Penolakan menyertakan alasan yang aman |
| Status penanganan berubah | Pelapor/pengikut sesuai fitur | Ambil status terbaru dari backend |
| Komentar baru | Pelapor atau pengguna yang berlangganan | Hindari spam |
| Aktivitas vote | Pelapor, bila diaktifkan | Sebaiknya dikelompokkan |
| Laporan masuk antrean | Admin area terkait | Tidak boleh bocor ke admin di luar cakupan |
| Pengumuman terbit | Pengguna sesuai preferensi | Terapkan rate/frequency limit |

### 10.2 Reliabilitas

- Gunakan pola outbox bila diperlukan agar perubahan data dan pencatatan notifikasi tidak terpisah secara tidak konsisten.
- Proses pengiriman FCM harus mendukung retry dan idempotensi.
- Kegagalan notifikasi tidak boleh membatalkan perubahan status yang valid.
- Token perangkat yang tidak valid harus dapat dinonaktifkan.
- Jangan menganggap notifikasi terkirim sebagai bukti pengguna sudah membaca.

---

## 11. Audit Log dan Akuntabilitas

### 11.1 Peristiwa Minimum yang Dicatat

- Pembuatan laporan dan perubahan field penting.
- Perubahan status penanganan dan publikasi.
- Penahanan akibat threshold downvote.
- Keputusan publish, reject, cancel, atau archive.
- Perubahan konfigurasi ambang dan kebijakan.
- Perubahan role dan penugasan admin.
- Penghapusan atau penyembunyian komentar/lampiran.
- Perubahan status antrean moderasi.
- Percobaan aksi sensitif yang ditolak, bila sesuai kebutuhan keamanan.

### 11.2 Isi Audit

Audit event setidaknya memuat:
- aktor (pengguna/admin/sistem);
- aksi dan entitas;
- nilai sebelum/sesudah yang relevan;
- alasan/kode alasan;
- timestamp;
- request/event correlation ID;
- snapshot jumlah upvote/downvote ketika threshold memicu;
- sumber proses bila relevan (API, scheduler, fungsi database).

Audit log harus append-only dari jalur aplikasi, dengan akses baca dibatasi. Untuk kebutuhan audit yang lebih kuat, pertimbangkan proteksi tambahan dan pemantauan perubahan administratif.

---

## 12. Non-Functional Requirements

### NFR-01 — Keamanan
- Semua tabel API-facing memakai RLS.
- Tidak ada rahasia backend di aplikasi klien.
- Mutasi sensitif divalidasi server-side.
- Akses lintas wilayah mengikuti penugasan admin.

### NFR-02 — Konsistensi
- Transisi status, pembuatan antrean, dan pencatatan event yang berkaitan harus transaksional.
- Operasi vote idempoten dan tidak menggandakan suara.
- Aturan visibilitas publik konsisten pada semua endpoint dan cache.

### NFR-03 — Kinerja
- Feed menggunakan pagination dan indeks yang sesuai.
- Buat indeks untuk status publikasi/tanggal, area/status, vote unik, komentar per laporan, dan geospasial.
- Tetapkan target latency dan kapasitas berdasarkan uji beban sebelum rilis; angka final belum ditentukan.

### NFR-04 — Aksesibilitas dan UX
- Status laporan menggunakan label dan penjelasan yang jelas, bukan warna saja.
- Alasan penolakan ditampilkan secara aman kepada pemilik laporan.
- Kesalahan validasi lokasi/file ditampilkan dengan instruksi yang dapat ditindaklanjuti.
- Konfirmasi aksi destruktif dan tampilkan alasan keputusan moderasi yang relevan.

### NFR-05 — Observabilitas
- Log error terstruktur dan correlation ID untuk mutasi penting.
- Pantau kegagalan upload, antrean moderasi yang menumpuk, proses arsip terlambat, dan kegagalan FCM.
- Hindari mencatat token, password, atau data pribadi yang tidak diperlukan.

### NFR-06 — Portabilitas
- Skema dan aturan bisnis dikelola melalui migrasi yang ditinjau.
- Fungsi backend dan policy diuji di lingkungan staging sebelum produksi.
- Perubahan konfigurasi kebijakan memiliki versi atau jejak audit.

---

## 13. Acceptance Criteria

Kriteria di bawah dapat digunakan sebagai checklist QA. Semua skenario keamanan harus diuji melalui API langsung, bukan hanya lewat UI.

### 13.1 Autentikasi dan Peran

- [ ] Pengguna dapat login melalui Google dan profilnya tersedia.
- [ ] Profil baru mendapat `role = user`.
- [ ] Pengguna biasa tidak dapat mengubah role menjadi `admin` melalui REST/RPC/Storage/API.
- [ ] Admin hanya dapat menjalankan aksi dalam area penugasannya.
- [ ] Admin di luar area tidak dapat membaca atau mengubah laporan privat di area lain.
- [ ] Perubahan role/penugasan tercatat dalam audit log.

### 13.2 Pembuatan dan Edit Laporan

- [ ] Pengguna terautentikasi dapat membuat laporan valid.
- [ ] Lokasi di luar poligon layanan ditolak oleh backend/database.
- [ ] Upload dengan tipe atau ukuran file terlarang ditolak.
- [ ] Pengguna tidak dapat mengklaim lampiran milik pengguna lain.
- [ ] Pemilik hanya dapat mengedit field yang diizinkan.
- [ ] Pemilik tidak dapat mengubah status, area otorisasi, alasan moderasi, atau timestamp terminal.
- [ ] Perubahan substantif setelah publikasi/interaksi memicu pembatasan atau review sesuai kebijakan.
- [ ] Perubahan penting memiliki jejak audit.

### 13.3 Publikasi dan Visibilitas

- [ ] Laporan `published` nonterminal tampil pada feed dan detail publik.
- [ ] Laporan `pending_review` dan `held` tidak tampil di feed, pencarian, atau detail publik.
- [ ] Laporan `rejected` langsung hilang dari seluruh endpoint publik.
- [ ] Laporan `cancelled` langsung hilang dari seluruh endpoint publik.
- [ ] UUID laporan nonpublik tidak dapat digunakan untuk melewati pemeriksaan akses.
- [ ] Lampiran laporan nonpublik tidak dapat diakses melalui URL publik yang masih berlaku secara permanen.
- [ ] Cache, pencarian, dan notifikasi tidak terus menampilkan laporan yang telah disembunyikan.

### 13.4 Vote dan Threshold Downvote

- [ ] Satu pengguna hanya memiliki satu vote aktif per laporan.
- [ ] Pengguna dapat mengganti atau mencabut vote saat laporan masih eligible.
- [ ] Vote ditolak ketika laporan tidak `published` atau sudah terminal.
- [ ] Threshold hanya dievaluasi setelah jumlah suara minimum tercapai.
- [ ] Persentase downvote dihitung dari vote aktif, bukan vote yang dicabut.
- [ ] Saat threshold tercapai, laporan masuk `held` dan antrean review dibuat secara atomik.
- [ ] Threshold tidak otomatis mengubah status penanganan menjadi `cancelled`.
- [ ] Vote paralel tidak menghasilkan antrean ganda atau state yang tidak konsisten.
- [ ] Snapshot vote dan pemicu tercatat di moderation event/audit log.

### 13.5 Komentar dan Moderasi

- [ ] Komentar hanya bisa dibuat pada laporan publik aktif.
- [ ] Komentar baru ditolak setelah laporan `held`, `rejected`, `cancelled`, atau `archived`.
- [ ] Komentar yang dimoderasi tidak tampil publik tetapi jejak internal sesuai kebijakan tetap ada.
- [ ] Hanya admin berwenang yang dapat menyelesaikan antrean moderasi.
- [ ] Keputusan reject wajib memiliki alasan.
- [ ] Keputusan cancel wajib memiliki alasan atau kode keputusan.
- [ ] Semua keputusan moderasi tercatat dengan aktor, waktu, alasan, dan state sebelum/sesudah.

### 13.6 Status Penanganan dan Pengarsipan

- [ ] Transisi status ilegal ditolak di backend/database.
- [ ] Transisi ke `completed` ditolak jika bukti penyelesaian valid belum tersedia.
- [ ] Saat status menjadi `rejected` atau `cancelled`, `terminal_at` diisi dan visibilitas publik dicabut segera.
- [ ] `archive_after` ditetapkan menjadi `terminal_at + 24 jam`.
- [ ] Setelah 24 jam, proses terjadwal mengubah state publikasi menjadi `archived`.
- [ ] Pengarsipan tidak menghapus data internal atau audit log secara otomatis.
- [ ] `held` tidak memulai timer 24 jam.

### 13.7 Audit, Keamanan, dan Notifikasi

- [ ] Audit log mencatat perubahan penting dan tidak dapat diedit oleh klien.
- [ ] Tidak ada service role key dalam bundle aplikasi.
- [ ] RLS diuji untuk anonim, user, pemilik laporan, admin area yang benar, dan admin area yang salah.
- [ ] Kegagalan FCM tidak menggagalkan transaksi bisnis yang valid.
- [ ] Proses notifikasi memiliki retry/idempotensi sesuai rancangan.
- [ ] Rate limit mencegah spam laporan, vote, komentar, dan flag.
- [ ] Tidak ada data sensitif yang bocor lewat pesan error atau notifikasi.

---

## 14. Indikator Keberhasilan

Target angka harus ditetapkan setelah baseline atau pilot. Indikator awal:
- Persentase laporan dengan informasi dan lokasi yang cukup untuk ditindaklanjuti.
- Waktu median dari laporan dibuat hingga review pertama.
- Waktu median dari laporan diterima hingga penanganan dimulai.
- Persentase laporan selesai dengan bukti penyelesaian valid.
- Tingkat laporan yang ditahan oleh threshold tetapi kemudian dipublikasikan kembali.
- Rasio laporan spam/duplikat terhadap semua laporan.
- Waktu penyelesaian antrean moderasi.
- Tingkat kegagalan notifikasi dan upload.
- Jumlah percobaan akses tidak sah yang berhasil (target: nol).

---

## 15. Indeks dan Pertimbangan Implementasi

Indeks awal yang disarankan:
- `reports(publication_state, published_at DESC)`
- `reports(area_id, handling_status, created_at DESC)`
- indeks unik `reports(report_number)`
- indeks unik `report_votes(report_id, user_id)`
- `report_comments(report_id, created_at)`
- `moderation_events(report_id, created_at)`
- indeks spasial GiST pada `areas.boundary` dan `reports.location`
- indeks `report_moderation_queue(queue_status, created_at)`

Implementasi arsip 24 jam membutuhkan scheduled job/cron atau worker tepercaya. Pastikan worker idempoten, memproses batch, dan menulis audit event. Jangan mengandalkan aplikasi klien yang kebetulan sedang terbuka.

---

## 16. Keputusan yang Masih Harus Difinalisasi

Hal berikut belum menjadi keputusan final dan harus disepakati sebelum produksi:

1. **Ambang downvote final:** jumlah suara minimum, jumlah downvote minimum, dan persentase minimum. Nilai 10 total suara, 6 downvote, dan 70% hanyalah rekomendasi awal untuk pilot.
2. **Retensi data internal:** berapa lama laporan, komentar, vote, lampiran, dan audit disimpan sebelum penghapusan permanen atau anonimisasi.
3. **Cakupan wilayah MVP:** provinsi/kabupaten/kota mana yang aktif dan sumber poligon batas resminya.
4. **Aturan auto-publish:** kriteria tepat untuk laporan yang langsung dipublikasikan versus yang masuk review awal.
5. **Edit terbatas:** batas waktu, batas perubahan deskripsi, serta kondisi pasti yang memerlukan persetujuan admin.
6. **Kebijakan vote:** apakah vote sendiri diizinkan bagi admin, dan apakah aktivitas vote memicu notifikasi individual atau agregat.
7. **Komentar:** apakah komentar bisa diedit, berapa lama, dan bagaimana penanganan balasan.
8. **Pengumuman:** siapa yang boleh menerbitkan untuk satu wilayah atau seluruh wilayah.
9. **Batas file:** ukuran maksimum, format yang diterima, jumlah lampiran, dan durasi maksimum video.
10. **Target operasional:** SLA review, kapasitas, latency, backup, dan pemulihan bencana.

---

## 17. Rekomendasi Urutan Implementasi

1. **Fondasi data dan keamanan:** skema, migrasi, RLS, profil, peran, area, dan validasi lokasi.
2. **CRUD laporan dan lampiran:** upload aman, edit terbatas, feed dan detail dengan aturan visibilitas konsisten.
3. **State machine:** fungsi transisi status, riwayat, alasan reject/cancel, dan bukti completion.
4. **Interaksi komunitas:** vote, komentar, perhitungan threshold atomik, `held`, dan moderation queue.
5. **Panel admin:** review, moderasi, penugasan wilayah, dan audit.
6. **Notifikasi:** outbox, worker, FCM, retry, dan preferensi.
7. **Arsip dan operasional:** scheduler 24 jam, observabilitas, backup, uji beban, dan uji keamanan.
8. **Pilot terkontrol:** ukur kualitas laporan, beban moderasi, tingkat manipulasi vote, dan sesuaikan konfigurasi.

---

## 18. Definisi Selesai (Definition of Done)

MVP dinyatakan siap dirilis setelah:
- Semua acceptance criteria prioritas tinggi lulus.
- RLS dan Storage policies lulus pengujian lintas peran dan lintas wilayah.
- Transisi status serta threshold diuji dalam kondisi bersamaan.
- Tidak ada jalur publik yang mengungkap laporan `held`, `rejected`, `cancelled`, atau `archived`.
- Pengarsipan 24 jam berjalan lewat proses server-side dan idempoten.
- Audit log tersedia untuk aksi sensitif.
- Tidak ada secret backend di aplikasi klien.
- Proses backup/restore dan penanganan kegagalan worker diuji.
- Keputusan terbuka pada Bagian 16 diselesaikan atau secara eksplisit diterima sebagai batasan pilot.

---

## Lampiran A — Aturan Visibilitas Publik

Gunakan satu predicate konseptual yang ditegakkan di backend/database:

```sql
publication_state = 'published'
AND handling_status NOT IN ('rejected', 'cancelled')
```

Kondisi tersebut adalah batas minimum. Tambahkan pemeriksaan area, moderasi, privasi lampiran, dan kebijakan lain yang relevan. Semua endpoint publik dan mutasi interaksi harus menggunakan aturan yang sama.

## Lampiran B — Ringkasan Keputusan Produk

- Ambang downvote berbasis persentase dengan jumlah suara minimum.
- Ketika ambang tercapai: `held` dan review admin, bukan pembatalan otomatis.
- Laporan `rejected`/`cancelled` langsung tersembunyi dari publik dan interaksi dinonaktifkan.
- Setelah 24 jam: arsip tampilan publik/internal, bukan penghapusan permanen.
- Edit laporan dibatasi sesuai status, interaksi, dan progres penanganan.
- Penanganan dan publikasi menggunakan state machine terpisah.
- RLS dan validasi backend adalah otoritas utama.
- Data audit dan riwayat dipertahankan sesuai kebijakan retensi yang akan difinalisasi.
