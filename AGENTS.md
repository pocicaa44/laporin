# AGENTS.md — Laporin

Dokumen ini adalah konteks dan aturan kerja untuk AI coding agent pada repository Laporin. Baca sebelum melakukan perubahan. Periksa repository aktual; jangan menganggap detail yang belum diverifikasi sebagai fakta.

## 1. Misi Agent

Bertindak sebagai engineer yang memahami produk, menjaga keamanan dan konsistensi data, menggunakan dokumentasi package terbaru melalui Context7, serta mengoptimalkan berdasarkan pengukuran.

Untuk setiap task:
1. Pahami permintaan dan acceptance criteria.
2. Inspeksi struktur repository, kode, konfigurasi, migration, test, `pubspec.yaml`, dan lockfile sebelum mengubah kode.
3. Cari dokumentasi Context7 untuk API package yang relevan dan cocokkan dengan versi yang dipakai.
4. Buat perubahan sekecil mungkin yang menyelesaikan kebutuhan secara utuh.
5. Jalankan formatter, analyzer/linter, test, dan build yang relevan.
6. Tinjau `git diff`; laporkan perubahan, validasi, asumsi, dan risiko.
7. Jangan pernah mengklaim test berhasil jika belum dijalankan atau gagal.

Jangan menimpa perubahan pengguna yang belum di-commit. Jangan mengerjakan refactor luas yang tidak diperlukan.

## 2. Konteks Produk

Laporin adalah aplikasi pelaporan masalah publik dalam cakupan geografis yang dikonfigurasi. Pengguna membuat laporan dengan judul, deskripsi, lokasi, dan lampiran; memantau progres; serta berinteraksi melalui thread publik.

Satu laporan adalah satu sumber data untuk dua pengalaman:
- **Laporan:** detail dan progres yang dapat dipantau pemilik.
- **Thread:** laporan yang dipublikasikan, dengan vote, komentar, dan pembaruan.

Jangan menduplikasi record hanya untuk memisahkan tampilan.

### Stack yang direncanakan
- Client: Flutter untuk mobile dan web.
- Backend/database/auth/storage: Supabase (Postgres, Auth, Storage, RLS, fungsi backend sesuai implementasi).
- Push notification: Firebase Cloud Messaging (FCM).
- Dokumentasi package: Context7 dan dokumentasi resmi upstream.

Stack ini adalah konteks produk, bukan bukti dependency sudah terpasang. Verifikasi `pubspec.yaml`, lockfile, folder source, konfigurasi platform, dan migration sebelum memilih API atau menambah package.

### Fitur inti
- Login Google, profil, role `user`/`admin`.
- CRUD laporan dengan edit terbatas.
- Validasi lokasi terhadap batas wilayah resmi.
- Feed/detail publik, upvote/downvote, komentar.
- Review dan moderasi admin.
- Status penanganan, bukti penyelesaian foto/video.
- Pengumuman admin dan FCM.
- Riwayat status, moderation queue, audit log.
- Penyembunyian publik dan pengarsipan laporan terminal.

## 3. Invarian Produk yang Wajib Dijaga

### 3.1 Dua state machine terpisah

Status penanganan (`handling_status`):
- `new`
- `accepted`
- `in_progress`
- `completed`
- `rejected`
- `cancelled`

Status publikasi/moderasi (`publication_state`):
- `pending_review`
- `published`
- `held`
- `archived`

Jangan menggabungkan keduanya atau menyimpulkan state publik hanya dari status penanganan.

### 3.2 Visibilitas publik

Syarat minimum agar laporan dapat dibaca sebagai konten publik:

```sql
publication_state = 'published'
AND handling_status NOT IN ('rejected', 'cancelled')
```

Ini syarat minimum; izin, cakupan area, dan privasi lampiran tetap wajib diperiksa. Aturan yang sama harus konsisten pada feed, search, detail, vote, komentar, lampiran, cache, dan notifikasi.

- `pending_review`: privat/tidak tampil publik.
- `held`: langsung disembunyikan dan masuk antrean moderasi.
- `rejected`: langsung disembunyikan dan interaksi dinonaktifkan.
- `cancelled`: langsung disembunyikan dan interaksi dinonaktifkan.
- `archived`: tidak tampil publik.
- Jangan mengandalkan filter UI sebagai kontrol keamanan.

### 3.3 Threshold downvote

- Persentase dihitung dari vote aktif: `downvotes / (upvotes + downvotes) * 100`.
- Vote yang dicabut tidak dihitung.
- Maksimal satu vote aktif per user per laporan.
- Gunakan minimum jumlah vote dan persentase threshold yang dapat dikonfigurasi.
- Ketika threshold tercapai, tahan laporan (`held`) dan buat moderation queue secara atomik.
- Threshold **tidak** otomatis membatalkan laporan.
- Nilai final belum diputuskan. Contoh `10` total vote, `6` downvote, `70%` hanya rekomendasi awal untuk pilot, bukan konstanta permanen.

### 3.4 Reject, cancel, dan arsip 24 jam

- `rejected` wajib memiliki alasan.
- `cancelled` wajib memiliki alasan atau kode keputusan.
- Begitu laporan menjadi `rejected`/`cancelled`, cabut visibilitas publik dan semua interaksi baru **seketika**, bukan setelah 24 jam.
- Catat `terminal_at`; tetapkan `archive_after = terminal_at + 24 hours`.
- Setelah 24 jam, proses server-side mengubah publikasi menjadi `archived`.
- Arsip tampilan publik bukan penghapusan data internal. Retensi internal masih harus difinalisasi.
- `held` bukan status terminal dan tidak memulai timer 24 jam.

### 3.5 Aturan lain
- Transisi ke `completed` memerlukan bukti penyelesaian yang valid.
- Pemilik hanya dapat mengedit field yang diizinkan. Status, role, alasan moderasi, area otorisasi, timestamp terminal, dan audit tidak boleh diedit oleh client.
- Perubahan substantif setelah publikasi, vote/komentar, atau dimulainya penanganan dapat dibatasi atau memerlukan review.
- User baru default `user`. Client tidak dapat mengangkat dirinya menjadi admin.
- Admin hanya bertindak pada area yang ditugaskan. Jangan menganggap semua admin memiliki akses global.
- Semua mutasi sensitif divalidasi di backend/database; menyembunyikan tombol di UI tidak cukup.

## 4. Workflow Sebelum Coding

1. Periksa struktur direktori dan file terkait.
2. Baca kode yang berjalan dan ikuti pola repository untuk routing, state management, data access, error handling, dan testing.
3. Periksa versi dependency dari manifest dan lockfile.
4. Untuk perubahan backend, baca migration, function/RPC, trigger, RLS, dan Storage policy terkait.
5. Tentukan happy path, failure path, acceptance criteria, dan dampak ke caller.
6. Gunakan Context7 untuk dokumentasi API yang relevan.
7. Jangan menambah dependency, cache, abstraction, atau concurrency tanpa kebutuhan yang jelas.
8. Jika keputusan produk belum final, jangan mengunci nilai permanen. Cari konfigurasi existing; jika tidak ada, gunakan asumsi aman dan dokumentasikan.
9. Jangan menghapus test atau melonggarkan validasi/RLS untuk membuat build lulus.
10. Jangan pernah memasukkan secret ke source code, log, fixture, screenshot, atau contoh.

## 5. Context7 — Wajib untuk Dokumentasi Package

Context7 adalah sumber utama agent untuk memverifikasi dokumentasi package/API yang digunakan. Gunakan dokumentasi yang cocok dengan versi dependency aktual; jangan otomatis memakai API versi terbaru jika project belum menggunakannya.

### Prosedur
1. **Identifikasi package dan versi:** cek `pubspec.yaml`, `pubspec.lock`, versi Flutter/Dart, dan manifest/lockfile lain bila ada.
2. **Cari library di Context7:** gunakan tool Context7 yang tersedia di environment agent. Pastikan library resmi dan tidak tertukar dengan package bernama mirip.
3. **Ambil dokumentasi topik spesifik:** API, contoh resmi, konfigurasi platform, error handling, breaking changes, deprecations, migration guide, dan keterbatasan versi.
4. **Cocokkan versi:** bila dokumentasi menunjukkan API versi lebih baru, gunakan API yang sesuai versi project atau ajukan upgrade eksplisit. Jangan upgrade dependency sebagai efek samping tanpa alasan.
5. **Implementasikan dan verifikasi:** jalankan analyzer, test, build, atau contoh minimal yang relevan.
6. **Catat sumber:** dalam ringkasan task, sebutkan package/topik Context7 yang diperiksa.
7. **Jika Context7 tidak tersedia:** jangan berpura-pura menggunakannya. Nyatakan keterbatasan dan pakai dokumentasi resmi upstream/source code sesuai versi.

### Package/topik yang lazim diverifikasi
Gunakan hanya bila relevan:
- Flutter SDK dan Dart.
- Supabase Flutter/client, Supabase Auth, Postgres, RLS, Storage, Edge Functions, Supabase CLI.
- Firebase Messaging dan konfigurasi native.
- Router, state management, dependency injection, form validation, image picker, maps/geolocation, serialization, code generation.
- Testing framework, linter, build tools, dan package web yang benar-benar digunakan.

Context7 bukan pengganti test, audit keamanan, atau pembacaan source code. Jangan mengarang API, mengandalkan snippet yang tidak cocok versi, atau menyalin contoh tanpa menyesuaikan lifecycle dan error handling.

## 6. Arsitektur dan Kualitas Kode

- Pisahkan UI, state/presentation logic, aturan domain, dan data access sesuai pola project.
- Aturan bisnis kritis tidak boleh hanya ada di widget/client.
- Hindari duplikasi aturan status dan visibilitas; buat satu sumber aturan yang dapat diuji.
- Gunakan model bertipe dan validasi yang eksplisit; hindari `dynamic` atau cast tidak aman jika bisa dihindari.
- Validasi input di UI untuk UX dan ulangi validasi penting di backend untuk keamanan.
- Bedakan error validasi, otorisasi, jaringan, konflik state, dan server.
- Tangani loading, success, empty, error, dan retry state.
- Cegah request ganda saat rebuild/interaksi berulang.
- Kelola lifecycle: dispose controller, listener, stream, dan animation controller dengan benar.
- Operasi yang di-retry harus idempoten atau memiliki perlindungan duplikasi.
- Operasi data yang harus berhasil/gagal bersama perlu transaksi atau fungsi backend yang tepat.
- Patuhi kebiasaan koding di `skills.md`: utamakan metode paling mudah & efisien, hindari penumpukan method yang membebani stack dan menyulitkan debug, konsisten menggunakan kembali method yang sudah ada (strict DRY), serta jaga ukuran file agar modular dan tidak menumpuk ribuan baris kode.
- Gunakan constraint database untuk invariant yang bisa ditegakkan pada data.

## 7. Supabase, RLS, Storage, dan Backend Security

1. Aktifkan RLS pada semua tabel yang terekspos ke client API.
2. Terapkan least privilege; uji `SELECT`, `INSERT`, `UPDATE`, dan `DELETE` secara terpisah.
3. Jangan menaruh Supabase `service_role` key dalam Flutter/mobile/web.
4. Jangan percaya `role`, `author_id`, `area_id`, status, alasan moderasi, atau kolom audit yang dikirim client tanpa validasi otoritatif.
5. Mutasi status, moderasi, threshold, dan assignment harus lewat jalur backend/database tepercaya.
6. Fungsi berprivilege harus memvalidasi caller, membatasi hak eksekusi, mengamankan `search_path` bila relevan, dan mencegah privilege escalation.
7. RLS bukan pengganti constraint database atau validasi bisnis.
8. Storage policy harus mengikuti izin parent report dan jenis lampiran. Jangan membuat bucket public hanya demi kemudahan.
9. Signed URL harus punya masa berlaku yang sesuai; bukan pengganti otorisasi permanen.
10. Mengetahui UUID tidak boleh memberi akses ke laporan privat (hindari IDOR).
11. Validasi koordinat di backend/database terhadap poligon area layanan, bukan sekadar mempercayai nama lokasi dari client.
12. Catat aktor, waktu, alasan, state sebelum/sesudah, dan correlation ID untuk aksi sensitif.
13. Jangan melonggarkan RLS untuk mengatasi bug tanpa pengganti dan test yang jelas.

Uji setidaknya dengan anon, user biasa, pemilik laporan, admin dengan assignment yang benar, admin tanpa assignment, serta worker/backend tepercaya. Periksa akses data, mutasi, lampiran, role, dan status.

## 8. Metode Optimasi Aplikasi

Optimasi harus berbasis profiling dan pengukuran. Prioritas: correctness, keamanan, UX, kemudian performa. Jangan mengorbankan keamanan atau maintainability demi micro-optimization yang belum terbukti.

### Proses optimasi
1. Tentukan gejala dan metrik.
2. Ukur baseline pada perangkat/runtime yang relevan.
3. Profilkan dan identifikasi bottleneck utama.
4. Ubah satu kelompok penyebab dalam satu waktu.
5. Jalankan test regresi dan ukur ulang pada kondisi sebanding.
6. Laporkan hasil sebelum/sesudah dan trade-off.
7. Jangan klaim performa meningkat tanpa hasil pengukuran yang bisa diulang.

### Flutter UI dan rendering
- Gunakan `const` untuk widget immutable saat sesuai.
- Gunakan list lazy seperti `ListView.builder`/sliver untuk daftar panjang.
- Pecah widget berdasarkan tanggung jawab dan kebutuhan rebuild, bukan hanya panjang file.
- Jangan melakukan I/O, parsing berat, atau sorting besar di `build`.
- Batasi rebuild ke subtree yang berubah menggunakan pola state management yang sudah ada.
- Jangan membuat listener/subscription berulang saat build; kelola lifecycle dengan benar.
- Hindari efek mahal berlebihan pada list panjang: blur, opacity, clipping, intrinsic layout, dan animasi yang tidak perlu.
- Gunakan thumbnail untuk feed dan resolusi penuh saat detail diperlukan.
- Hindari memuat semua laporan, komentar, atau lampiran sekaligus.
- Uji loading, empty, error, retry, dan stale state.
- Gunakan Flutter DevTools untuk frame timing, rebuild, memory, dan network bila tersedia.
- Ukur di profile/release mode untuk evaluasi performa, bukan hanya debug mode.

### Network dan Supabase
- Pilih kolom yang diperlukan; hindari payload besar atau `select *` tanpa alasan.
- Gunakan pagination untuk feed, komentar, dan queue.
- Filter/sort di server jika dataset besar.
- Hindari N+1 request; gunakan query relasi/batch yang didukung dan tetap aman.
- Debounce search, lindungi dari stale response, dan batalkan request jika tepat serta didukung library.
- Hindari request sama dari banyak widget; gunakan repository/cache jika pola project mendukung.
- Cache harus memiliki invalidation yang jelas. Status moderasi harus segera invalidated agar laporan terminal tidak tampil dari cache.
- Buat indeks berdasarkan pola query aktual dan periksa query plan dengan `EXPLAIN (ANALYZE, BUFFERS)` jika tersedia dan aman.
- Hindari indeks berlebihan karena menambah biaya write/storage.
- Jangan menjalankan rangkaian mutasi client yang seharusnya transaksional.
- Jangan konek langsung ke database dari aplikasi client.
- Retry hanya untuk operasi aman diulang atau yang memiliki idempotency protection.

### Gambar dan file
- Validasi tipe, ukuran, dan dimensi; validasi backend tetap wajib.
- Pertimbangkan resize/compress client untuk mengurangi transfer, dengan kualitas dan dukungan platform yang teruji.
- Jangan memproses file besar pada UI isolate jika menyebabkan jank; gunakan isolate/worker hanya bila profiling membuktikan perlu.
- Upload harus memiliki progress dan retry tanpa membuat duplikat.
- Jangan mengunduh video atau gambar full-resolution hanya untuk thumbnail.
- Sinkronkan izin file, signed URL, cache, dan status publikasi.

### Flutter Web (jika diaktifkan)
- Ukur bundle size dan loading awal.
- Hindari dependency besar di jalur startup tanpa alasan.
- Tunda fitur/data non-esensial bila arsitektur mendukung lazy loading.
- Uji responsive layout dan aksesibilitas keyboard.
- Gunakan browser Network/Performance tools untuk mencari asset besar, request berulang, dan long tasks.
- Jangan mengasumsikan optimasi mobile memberi hasil sama di web.

### Database dan background jobs
- Pertimbangkan indeks untuk status publikasi/tanggal, area/status, komentar per laporan, moderation queue, vote unik, dan geospatial query berdasarkan query nyata.
- Gunakan constraint untuk enum/status, vote unik, dan invariant penting.
- Gunakan PostGIS/geospatial query jika tersedia pada schema.
- Gunakan cursor/keyset pagination bila cocok untuk feed yang sering berubah.
- Arsip 24 jam dijalankan oleh server-side scheduler/worker, bukan aplikasi yang kebetulan terbuka.
- Scheduler harus idempoten, batch-aware, terpantau, dan mencatat hasil/error.
- Derived aggregate/materialized view hanya bila terbukti menjadi bottleneck dan invalidasinya jelas.

### Cache dan memory
- Cache hanya data yang aman dan mudah diinval idasi.
- Jangan menyimpan data sensitif secara lokal tanpa kebutuhan dan proteksi.
- Batasi cache gambar dan koleksi.
- Dispose semua resource yang memiliki lifecycle.
- Jangan menggunakan stale-while-revalidate untuk memberi akses ke laporan yang sudah nonpublik.

### Optimasi yang dilarang
- Melewati RLS atau validasi untuk menurunkan latency.
- Menampilkan cache `rejected`/`cancelled` sebagai konten publik.
- Menghapus audit demi throughput.
- Menambah cache global, isolates, denormalisasi, atau state management baru tanpa bukti.
- Mengklaim aplikasi lebih cepat tanpa benchmark.

## 9. Testing dan Quality Gates

Gunakan command yang tersedia pada repository; jangan mengasumsikan semua tooling terpasang.

Contoh untuk Flutter/Dart:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Jalankan test database/policy yang tersedia. Pastikan test mencakup:
- Laporan `pending_review`, `held`, `rejected`, `cancelled`, dan `archived` tidak tampil publik.
- `rejected`/`cancelled` tidak menerima vote/komentar baru.
- Threshold downvote memindahkan ke `held` dan queue, bukan cancel.
- Vote paralel dan vote dicabut menghasilkan perhitungan konsisten.
- `completed` gagal tanpa bukti valid.
- Reject/cancel gagal tanpa alasan.
- User tidak bisa mengubah role atau status server-managed.
- Admin lintas area tidak dapat memoderasi laporan yang tidak ditugaskan.
- Arsip 24 jam tidak menghapus data internal.
- Retry tidak menggandakan data/event yang harus idempoten.
- Storage policy mencegah akses lampiran privat.

Sebelum selesai:
- Jalankan formatter, analyzer/linter, test, dan build relevan.
- Tinjau `git diff` untuk perubahan tak sengaja, secret, debug code, atau generated file.
- Jika command tidak dapat dijalankan, sebutkan alasan sebenarnya.
- Jangan menyembunyikan test gagal.

## 10. Migration dan Kontrak API

- Migration harus dapat ditinjau dan mengikuti pola repository.
- Jangan mengedit migration yang sudah diterapkan di lingkungan bersama/produksi; buat migration baru kecuali workflow project menyatakan lain.
- Untuk perubahan breaking, pertimbangkan rollout bertahap: tambah struktur, deploy kompatibilitas, backfill, baru hapus struktur lama.
- Backfill harus aman dan bisa dilanjutkan setelah gagal.
- Jangan menghapus data produksi demi mempermudah migration.
- Perubahan enum/status harus memperbarui fungsi, policy, UI, query, analytics, dan test.
- Perubahan API harus mempertimbangkan client versi lama bila ada rollout bertahap.

## 11. Logging dan Observability

- Gunakan error type/message konsisten dengan pola project.
- Tampilkan pesan aman dan actionable; jangan bocorkan stack trace, SQL error, token, atau detail internal.
- Sertakan request/correlation ID untuk mutasi penting jika tersedia.
- Pantau kegagalan upload, query, FCM, queue moderasi yang menumpuk, dan proses arsip yang terlambat.
- Kegagalan FCM tidak boleh membatalkan mutasi bisnis yang sudah commit.
- Jangan log access token, refresh token, password, service role key, atau signed URL sensitif.

## 12. UI/UX dan Aksesibilitas

- Ikuti design system dan komponen yang sudah ada.
- Pertahankan konsistensi spacing, typography, warna, radius, dan navigasi.
- Status tidak boleh dibedakan hanya lewat warna.
- Sediakan loading, empty, error, success, retry, dan confirmation state.
- Konfirmasi tindakan berisiko tinggi seperti reject/cancel.
- Berikan alasan penolakan yang aman kepada pemilik; jangan bocorkan catatan internal.
- Form harus punya label, validasi, error message, dan dukungan keyboard di web.
- Jangan mengubah layar yang tidak terkait task tanpa kebutuhan.
- Mock data hanya untuk demo/test, jangan tercampur jalur produksi.

## 13. Keputusan yang Belum Final

Jangan menganggap hal berikut telah diputuskan:
- Threshold downvote final.
- Retensi internal dan penghapusan permanen.
- Wilayah MVP dan sumber poligon resmi.
- Kriteria pasti auto-publish versus review awal.
- Batas waktu dan aturan rinci edit laporan.
- Kebijakan vote admin dan frekuensi notifikasi vote.
- Batas ukuran/jumlah lampiran dan durasi video.
- SLA review, target performa, kapasitas, dan availability.

Jika task memerlukan keputusan yang belum final, cari konfigurasi/dokumen existing. Jika belum ada dan pekerjaan dapat dilanjutkan, gunakan opsi paling aman, buat configurable jika sesuai, dan tandai asumsi dengan jelas.

## 14. Format Ringkasan Setelah Task

Berikan ringkasan singkat dengan:
- **Perubahan:** fitur/bug yang diselesaikan.
- **File:** file penting yang dibuat/diubah.
- **Dokumentasi:** package/topik Context7 yang diperiksa; jika tidak tersedia, sebutkan sumber resmi alternatif.
- **Validasi:** command dan hasil aktual.
- **Keamanan/data:** dampak pada RLS, backend validation, migration, Storage, atau audit.
- **Catatan:** asumsi, keterbatasan, risiko, dan follow-up.

Jangan membuat klaim yang tidak didukung kode, command, atau dokumentasi yang benar-benar diperiksa.

## 15. Checklist Sebelum Merge

- [ ] Perubahan sesuai scope dan acceptance criteria.
- [ ] Context7 docs yang cocok dengan versi dependency telah diperiksa.
- [ ] Tidak ada secret atau konfigurasi sensitif yang ikut masuk.
- [ ] Aturan bisnis kritis ditegakkan backend/database.
- [ ] RLS dan Storage policies tetap least-privilege.
- [ ] Laporan nonpublik tidak bocor melalui feed, detail, search, cache, lampiran, atau interaksi.
- [ ] Transisi status, threshold, dan audit konsisten serta idempoten sesuai kebutuhan.
- [ ] Formatter, analyzer/linter, test, dan build relevan dijalankan.
- [ ] Klaim optimasi didukung pengukuran.
- [ ] `git diff` ditinjau dan dokumentasi diperbarui bila perlu.

## Prinsip Utama

**Correctness dan keamanan lebih penting daripada optimasi prematur.** Gunakan Context7 untuk dokumentasi dependency terkini yang sesuai versi project, test untuk membuktikan perilaku, dan profiling untuk membuktikan bottleneck. Pertahankan aturan bisnis Laporin di backend/database. Setiap keputusan moderasi harus dapat diaudit, dan laporan yang ditolak atau dibatalkan tidak boleh terlihat publik maupun menerima interaksi.
