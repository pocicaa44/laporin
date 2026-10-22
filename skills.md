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
