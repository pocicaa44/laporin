# Pedoman Kebiasaan Koding & Rekayasa Perangkat Lunak (skills.md)

Dokumen ini mendefinisikan prinsip koding, standar rekayasa, dan kebiasaan utama pengembang yang **wajib dipelajari dan ditiru oleh semua AI Coding Agent** yang bekerja pada proyek ini.

---

## 1. Tiga Prinsip Utama (Core Habits)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          KEBIASAAN KODING UTAMA                         │
├─────────────────────┬───────────────────────┬───────────────────────────┤
│ 1. Lean & Efficient │ 2. Strict DRY         │ 3. Clean & Modular        │
│    (Anti-Bloat)     │    (Reuse & Consistent)│    (Anti-God File)        │
│ Solusi paling mudah │ Gunakan method yang   │ Pecah file sebelum besar; │
│ & efisien, stack    │ sudah ada, hindari    │ hindari file ribuan baris │
│ dangkal, mudah debug│ duplikasi method      │ kode                      │
└─────────────────────┴───────────────────────┴───────────────────────────┘
```

---

## 2. Rincian Kebiasaan & Aturan Kerja

### 2.1. Lean, Efisien, & Bebas Tumpukan Method (Anti-Method Bloat)

> *"Pilih metode paling mudah, paling langsung, dan paling efisien. Jangan membuat wrapper atau method bertingkat yang tidak memberi nilai tambah."*

* **KISS (Keep It Simple, Straightforward):** Selesaikan masalah dengan cara yang paling bersih dan ringkas. Jangan membuat abstraksi sebelum terbukti diperlukan.
* **Hindari Call-Stack Bertingkat (No Deep Nesting):** Jangan membuat rantai panggilan: `methodA()` memanggil `methodB()`, yang hanya memanggil `methodC()`, yang membungkus fungsi bawaan. Hal ini:
  * Menambah overhead alokasi memori dan eksekusi pada runtime.
  * Memperpanjang jejak stack trace sehingga sulit di-debug saat terjadi exception.
* **Kemudahan Debugging (Debuggability First):**
  * Buat alur logika yang mudah ditelusuri dari titik awal (entry point) hingga akhir (exit point).
  * Pesan error dan penanganan exception harus jelas, spesifik, dan actionable.
* **Performa Aplikasi Terjaga:**
  * Di Flutter, hindari komputasi berulang atau instansiasi objek berat di dalam method `build()`.
  * Gunakan `const` constructor dan pemecahan widget lokal agar rebuild hanya terjadi pada subtree yang relevan.

---

### 2.2. Konsisten & Gunakan Kembali Method Eksisting (Strict DRY)

> *"Gunakan dan konsisten dengan method yang sudah pernah dibuat. Jangan membuat method dengan fungsi sama berulang-ulang."*

* **Inspeksi Kode Sebelum Menulis (Check Before You Code):**
  * Selalu cari method, helper, utility, service, atau extension yang sudah tersedia di codebase sebelum membuat fungsi baru.
  * Gunakan kata kunci fungsionalitas untuk mencari di folder `lib/core/`, `lib/shared/`, atau modul terkait.
* **Jangan Duplikasi Logika:**
  * Jika sebuah fungsi pemformatan tanggal, validasi string, HTTP handling, atau navigasi sudah ada, **wajib gunakan fungsi tersebut**.
  * Dilarang membuat variasi baru seperti `formatDate2()`, `customDateFormatter()`, atau menulis ulang parser yang esensinya sama.
* **Perluas Secara Aman (Extend, Don't Duplicate):**
  * Jika method eksisting butuh sedikit variasi, tambahkan parameter opsional dengan default value yang *backward-compatible*, daripada membuat method baru.
* **Standar Penamaan Konsisten:**
  * Gunakan konvensi penamaan yang seragam di seluruh layer (misal: `fetch...` untuk remote data, `get...` untuk sinkron/lokal cache, `on...` untuk UI event handler).

---

### 2.3. Clean Code & Modularitas (Anti-God File)

> *"Terapkan clean code agar file tidak menumpuk ribuan baris kode."*

* **Batas Panjang File (File Size Thresholds):**
  * **File UI/Widget:** Idealnya di bawah 150–200 baris. Jika mendekati 300 baris, pecah bagian UI/sub-komponen menjadi widget terpisah.
  * **File Logic/State/Service:** Idealnya di bawah 200–300 baris. Satu class hanya bertanggung jawab pada satu domain logic (Single Responsibility Principle).
  * **Dilarang keras:** Membiarkan sebuah file mencapai ribuan (1000+) baris kode ("God File" / "God Class").
* **Pemisahan Komponen (Component Extraction):**
  * Pecah bagian UI yang kompleks (misal form, header, item kartu, filter bar) ke dalam folder `components/` atau `widgets/` modular.
  * Buat widget independen yang menerima model data dan callback, sehingga mudah dites dan digunakan ulang.
* **Pemisahan Layer yang Tegas:**
  * **UI (View):** Hanya fokus pada presentasi dan rendering. Tidak boleh ada query database, parsing rumit, atau business rule di layer ini.
  * **Logic / Controller:** Mengatur alur data, input/output, dan interaksi pengguna.
  * **Service / Repository:** Mengelola komunikasi ke Supabase, API, storage, atau sensor perangkat.
  * **Model:** Entitas data bertipe kuat (strongly-typed).

---

## 3. Panduan untuk AI Agent (Agent Directives)

Setiap AI agent yang bekerja di repository ini **wajib** mengikuti protokol berikut sebelum dan sesudah melakukan perubahan kode:

### Langkah 1: Eksplorasi & Cek Method Eksisting (Pre-Flight Search)
```bash
# Contoh tindakan wajib agent:
# 1. Cari apakah helper / method serupa sudah pernah dibuat
# 2. Periksa service atau controller yang sudah menangani modul terkait
```
* **Tanyakan pada diri sendiri:** *"Apakah fungsi/method ini sudah ada di tempat lain di repo?"* Jika ya, pakai yang ada.

### Langkah 2: Perancangan yang Ramping (Lean Design)
* Pilih solusi paling sederhana dari library/framework resmi.
* Jangan membuat lapisan boilerplate baru kecuali benar-benar dibutuhkan oleh arsitektur proyek.
* Jangan membuat adapter atau wrapper jika pemanggilan langsung sudah bersih dan aman.

### Langkah 3: Kontrol Ukuran File (File Sizing Discipline)
* Saat menambahkan fitur baru ke file yang sudah ada:
  * Periksa panjang file saat ini.
  * Jika penambahan akan membuat file terlalu panjang (>300 baris), buat file/komponen baru terlebih dahulu, lalu impor.

### Langkah 4: Verifikasi & Self-Audit Sebelum Selesai
Sebelum melaporkan task selesai, agent harus memverifikasi checklist berikut:
- [ ] Apakah ada method duplikat yang baru saja saya buat padahal sudah ada fungsi serupa di tempat lain?
- [ ] Apakah ada wrapper/penumpukan method yang tidak perlu?
- [ ] Apakah alur kode mudah di-debug jika timbul error?
- [ ] Apakah ukuran file tetap ringkas, bersih, dan tidak menumpuk ratusan/ribuan baris?
- [ ] Apakah kode mematuhi linter (`flutter analyze` / `dart analyze`)?

---

## 4. Contoh Perbandingan (Do vs. Don't)

### Kasus A: Penumpukan Method (Method Stacking)

❌ **BURUK (Over-engineered, menumpuk method & memperberat stack):**
```dart
// Controller/Service yang menumpuk method tanpa nilai tambah
class ReportHelper {
  static String processTitle(String title) => _cleanTitle(title);
  static String _cleanTitle(String title) => _sanitize(title);
  static String _sanitize(String title) => title.trim();
}
```

✅ **BAIK (Langsung, efisien, mudah di-trace):**
```dart
// Langsung lakukan transformasi yang diperlukan atau gunakan method yang jelas
String sanitizeTitle(String title) => title.trim();
```

---

### Kasus B: Konsistensi vs Duplikasi Method (DRY)

❌ **BURUK (Membuat method baru yang fungsinya sama):**
```dart
// Di file A:
String formatTanggal(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

// Di file B baru dibuat lagi:
String displayDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);
```

✅ **BAIK (Konsisten menggunakan satu method utilitas/ekstensi):**
```dart
// lib/core/utils/date_formatter.dart (Digunakan bersama di file A dan file B)
extension DateTimeFormatX on DateTime {
  String toDisplayDate() => DateFormat('dd MMM yyyy').format(this);
}
```

---

### Kasus C: Ukuran File & Modularitas (Anti-God File)

❌ **BURUK (Satu file berisi UI, State, Form, dan puluhan widget bertumpuk hingga >1000 baris):**
```
lib/features/report/screens/create_report_screen.dart (1,250 baris)
  - _CreateReportScreenState
  - _buildHeader()
  - _buildCategoryPicker()
  - _buildLocationSection()
  - _buildMediaUploader()
  - _buildSubmitButton()
  - Semua API call & validasi inline
```

✅ **BAIK (Pecah modular, bersih, masing-masing < 150 baris):**
```
lib/features/report/
  ├── screens/
  │   └── create_report_screen.dart       (< 150 baris: mengorkestrasi komponen)
  ├── widgets/
  │   ├── report_category_picker.dart     (< 100 baris)
  │   ├── report_location_picker.dart     (< 120 baris)
  │   └── report_media_uploader.dart      (< 120 baris)
  └── controllers/
      └── create_report_controller.dart   (< 150 baris: state & business logic)
```

---

## 5. Performance Optimization & Async UI Standards

Standar ini wajib diterapkan pada seluruh fitur asinkron, interaksi UI, operasi media, dan pemrosesan data di aplikasi Laporin untuk menjamin kelancaran pada perangkat Android kelas bawah (*low-end devices*, RAM 1–2 GB).

### 5.1. Prinsip Utama (Low-End Devices First)
1. **Performance-First & Resource-Constrained Mindset:** Anggap aplikasi berjalan pada perangkat dengan prosesor hemat daya, RAM terbatas, dan jaringan seluler yang berfluktuasi.
2. **Immediate Interaction Feedback:** Setiap interaksi pengguna (ketukan tombol, swipe refresh, form submit) harus segera memberikan respons visual tanpa menunggu selesainya I/O jaringan.
3. **Bounded Resource Consumption:** Batasi konsumsi memori dan bandwidth secara tegas (cache memori gambar terbatas, decoding terukur, upload dengan konkurensi terkontrol).
4. **No UI Tearing / Screen Wipe:** Dilarang menghapus konten lama saat melakukan refresh atau pembaruan sebagian data.
5. **Data Correctness & Security First:** Jangan pernah melonggarkan validasi, otorisasi Supabase RLS, atau aturan bisnis produk (misal visibilitas publik atau soft-delete) demi optimasi performa semu.

### 5.2. Standar Loading & Feedback Interaksi Asinkron
1. **Pola Tombol & Anti-Double-Submission:**
   - Semua tombol aksi I/O (login, register, submit laporan, edit, vote, komentar, upload avatar) wajib memiliki feedback loading lokal (misal spinner kecil di dalam tombol).
   - Controller wajib memiliki guard in-flight:
     ```dart
     if (_isLoading) return false;
     _isLoading = true;
     notifyListeners();
     try {
       // async operation...
     } finally {
       _isLoading = false;
       notifyListeners();
     }
     ```
   - Tombol "Mulai Sekarang" pada alur onboarding/splash screen wajib mengunci interaksi dengan status `_isNavigating` dan menampilkan spinner saat inisialisasi sesi atau navigasi berlangsung.
2. **Pola Loading Berdasarkan Konteks:**
   - **Initial Page Load:** Tampilkan indikator tengah atau skeleton **hanya jika data kosong** (`controller.isLoading && controller.reports.isEmpty`).
   - **Pull-to-Refresh:** Pertahankan daftar lama tetap terlihat saat `RefreshIndicator` aktif; hindari me-replace seluruh `ListView` dengan `Center(CircularProgressIndicator())`.
   - **Pagination (Load More):** Tampilkan compact loader di bagian bawah daftar (`index == reports.length`).
   - **Upload Media:** Tampilkan progress bar atau overlay loading transparan dengan indikator jelas.
3. **Pengamanan Lifecycle Widget:**
   - Selalu periksa `if (_isDisposed) return;` sebelum memanggil `notifyListeners()`.
   - Di layer widget State, selalu periksa `if (!mounted) return;` sebelum menampilkan `SnackBar`, dialog, atau melakukan `Navigator.push/pop`.
   - Wajib melakukan `dispose()` pada semua `TextEditingController`, `ScrollController`, `AnimationController`, dan `Timer`.

### 5.3. Standar Fetching, Pagination & Rendering Data
1. **Lazy Rendering:**
   - Wajib menggunakan `ListView.builder` atau `SliverList` untuk daftar data dinamis.
   - Dilarang membungkus `Column` dengan `SingleChildScrollView` untuk menampilkan daftar laporan yang dapat bertambah.
2. **Pagination di Tingkat Repository & Controller:**
   - Gunakan ukuran halaman standar: `static const int pageSize = 10;`.
   - Controller menyediakan `hasMore`, `isLoadingMore`, dan method `loadMore()`.
   - Pasang `ScrollController` listener dengan ambang batas (threshold):
     ```dart
     void _onScroll() {
       if (_scrollController.hasClients &&
           _scrollController.position.pixels >=
               _scrollController.position.maxScrollExtent - 250) {
         context.read<FeedController>().loadMore();
       }
     }
     ```
3. **Pencegahan Race Condition & Request Duplikat:**
   - Terapkan in-flight lock pada request pagination (`if (_isLoading || _isRefreshing || _isLoadingMore || !_hasMore) return;`).
   - Terapkan debouncing (300 ms) pada kolom pencarian input teks sebelum memicu query data.
4. **Konsistensi Cache & Invalidation:**
   - Simpan entitas laporan terbaru di repository cache saat di-fetch.
   - Sinkronkan kembali laporan yang diperbarui di detail screen (`syncReport`) tanpa harus mengunduh ulang seluruh feed.

### 5.4. Standar Optimasi Gambar (Image Optimization)
1. **Global Image Cache Bounds:**
   - Di `main.dart`, konfigurasikan `PaintingBinding.instance.imageCache` agar aman dari Low Memory Killer (LMK) Android:
     ```dart
     PaintingBinding.instance.imageCache.maximumSizeBytes = 35 * 1024 * 1024; // 35 MB
     PaintingBinding.instance.imageCache.maximumSize = 100; // Maksimum 100 objek gambar
     ```
2. **Memory-Bounded Image Decoding:**
   - Gunakan komponen `AppImage` (`lib/core/widgets/app_image.dart`) untuk seluruh media laporan agar terhindar dari lonjakan RAM:
     - **Thumbnail Feed:** `memCacheWidth: 800` (tinggi diskalakan proporsional oleh Flutter agar tidak gepeng).
     - **Detail Screen Preview:** `memCacheWidth: 1200`.
     - **Full Resolution Viewer:** Khusus dialog penampil resolusi penuh (`PhotoViewerDialog`) untuk inspeksi bukti zoom-in.
   - **Foto Profil (Avatar):** Orientasi dan skala dipertahankan original dengan `BoxFit.cover` (tidak memaksakan decode `cacheWidth`/`cacheHeight` bujur sangkar yang mendistorsi foto non-1:1 menjadi gepeng atau stretch).
3. **Kompresi saat Pengambilan Foto:**
   - Foto bukti laporan: gunakan `MediaService.pickPhoto` dengan `maxWidth: 1920`, `maxHeight: 1080`, `imageQuality: 80`.
   - Foto profil avatar: gunakan `MediaService.pickAvatarImage` dengan mempertahankan orientasi dan resolusi original (`maxWidth: null, maxHeight: null`), hanya menerapkan kompresi kualitas JPEG (`imageQuality: 80`) agar hemat bandwidth dan tidak membebani server/storage.
   - Proteksi `ImagePicker`: Gunakan flag `_isPicking` dan tangani `PlatformException(already_active)` agar ketukan ganda tidak memunculkan error dialog/snackbar.
4. **Bounded Concurrency Upload:**
   - Saat mengunggah beberapa foto bukti, batasi upload paralel maksimal 2 file bersamaan untuk menghindari saturasi socket HTTP pada koneksi seluler lemah.
5. **Progressive Display & Graceful Fallback:**
   - Gunakan `frameBuilder` untuk transisi halus dari placeholder saat frame pertama siap dirender.
   - Selalu sediakan `errorBuilder` dengan widget fallback yang informatif saat file gagal dimuat.

### 5.5. Standar Pengujian & Quality Gates
Setiap optimasi wajib diverifikasi melalui pengujian nyata:
1. `dart format --output=none --set-exit-if-changed .`
2. `flutter analyze` (harus 0 errors dan 0 warnings baru).
3. `flutter test` (seluruh unit test dan widget test wajib hijau).
4. Verifikasi manual/automated terhadap kasus:
   - Double-tap cepat pada tombol aksi.
   - Pull-to-refresh saat daftar terisi (tidak ada flickering/screen tearing).
   - Pengguliran cepat daftar panjang untuk memantau konsumsi RAM.
   - Penggantian foto profil dan cache refresh.

### 5.6. Checklist Wajib Sebelum Perubahan Dianggap Selesai
AI Agent **wajib** memeriksa dan mematuhi checklist berikut sebelum menyatakan pekerjaan selesai:

- [ ] Apakah seluruh operasi asinkron/I/O memiliki indikator loading yang proporsional?
- [ ] Apakah seluruh aksi tombol dan form submit memiliki proteksi in-flight anti-double-submission?
- [ ] Apakah alur onboarding / splash screen ("Mulai Sekarang") mencegah aksi berulang saat bernavigasi?
- [ ] Apakah daftar laporan menerapkan lazy rendering (`ListView.builder`) dan pagination bertahap?
- [ ] Apakah pull-to-refresh mempertahankan data lama tanpa mengosongkan layar (*no screen wipe*)?
- [ ] Apakah seluruh gambar pada daftar, thumbnail, dan avatar menggunakan decode memory bounds (`AppImage`)?
- [ ] Apakah foto dikompresi dan di-resize sebelum diunggah ke storage backend?
- [ ] Apakah controller dan widget membersihkan resource (`dispose()`) dan memeriksa `mounted`/`_isDisposed`?
- [ ] Apakah aturan otorisasi, moderasi, status invariant, dan soft-delete tetap terjaga?
- [ ] Apakah `flutter analyze` dan `flutter test` dijalankan serta lulus tanpa error?

---

## 6. Anti-Context-Bleed & Production-Ready UI Copywriting

### Skill: Anti-Context-Bleed & Production-Ready UI Copywriting

#### 1. Deskripsi & Pemicu (When to Trigger)
Aktifkan skill ini setiap kali:
- Menulis, memodifikasi, atau merefactor kode antarmuka (UI components, widgets, screens, pages).
- Memberi nama/label pada tombol (button), link navigasi, header, tab, modal/dialog, placeholder form, atau empty-state message.
- Menerima instruksi pembuatan fitur antarmuka yang mengandung penjelasan intensi pengguna (contoh: "buat tombol start untuk mulai").

#### 2. Aturan Mutlak (Strict Directives)
1. **Dilarang Keras Menaruh Penjelasan dalam Tanda Kurung/Kurawal:**
   - JANGAN PERNAH menambahkan keterangan fungsi di samping label teks visual.
   - Contoh DILARANG: `"Start (Mulai)"`, `"Submit (Kirim Data)"`, `"Settings [Pengaturan]"`.
2. **Prinsip Konkret & Ringkas (1–3 Kata):**
   - Label tombol dan elemen aksi harus padat, jelas, dan siap produksi (production-ready).
   - Gunakan kata kerja aksi langsung tanpa kalimat berbunga atau edukatif.
3. **Pemisahan Teks Visual dan Aksesibilitas:**
   - Teks yang dirender ke layar HANYA label inti.
   - Jika membutuhkan deskripsi fungsional untuk pembaca layar (screen reader) atau panduan pengguna, masukkan HANYA ke atribut semantik (`tooltip`, `aria-label`, atau `Semantics(label: ...)`), bukan pada string visual.
4. **Isolasi Logika vs Copywriting:**
   - Jangan pernah mengubah variabel state, API route, ID elemen, atau handler fungsi saat merapikan teks antarmuka.

#### 3. Standar Perbandingan (Good vs Bad Examples)
- ❌ **SALAH:** `<button>Mulai (Mulai Ujian)</button>`
- ✅ **BENAR:** `<button>Mulai</button>`
- ❌ **SALAH:** `ElevatedButton(child: Text("Simpan (Menyimpan data)"))`
- ✅ **BENAR:** `ElevatedButton(child: Text("Simpan"))`
- ❌ **SALAH:** `"Keluar [Klik untuk logout dari akun]"`
- ✅ **BENAR:** `"Keluar"` (dengan tooltip terpisah jika relevan)

