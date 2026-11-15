<div align="center">
  <img src="assets/logo_laporin.png" alt="Laporin Logo" width="128" />

  # LAPORIN
  ### *Platform Pelaporan Masalah Fasilitas & Layanan Publik Modern Berbasis Geospasial*

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Platforms](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue?style=for-the-badge)]()
  [![Tests](https://img.shields.io/badge/Tests-350%2B%20Passing-brightgreen?style=for-the-badge)]()

  <p align="center">
    Menghubungkan warga dan pengelola fasilitas publik secara transparan, akuntabel, dan berbasis bukti nyata.
  </p>
</div>

---

## 📑 Daftar Isi
- [Tentang Laporin](#-tentang-laporin)
- [Fitur Utama](#-fitur-utama)
  - [Untuk Warga](#1-untuk-warga-civic-engagement)
  - [Untuk Admin & Petugas](#2-untuk-admin--petugas-governance--triage)
  - [Pengalaman Multi-Platform Responsif](#3-ekosistem-responsif-desktop--mobile)
- [Arsitektur & Tumpukan Teknologi](#-arsitektur--tumpukan-teknologi)
- [Invarian Bisnis & Protokol Keamanan](#-invarian-bisnis--protokol-keamanan)
- [Struktur Direktori](#-struktur-direktori)
- [Panduan Memulai (Getting Started)](#-panduan-memulai-getting-started)
  - [Prasyarat](#prasyarat)
  - [Instalasi](#langkah-instalasi)
  - [Konfigurasi Lingkungan (.env)](#konfigurasi-lingkungan-env)
  - [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Pengujian & Kualitas Kode](#-pengujian--kualitas-kode)
- [Filosofi Desain UI/UX](#-filosofi-desain-uiux)
- [Kontribusi & Lisensi](#-kontribusi--lisensi)

---

## 💡 Tentang Laporin

**Laporin** adalah aplikasi *civic-tech* berbasis **Flutter** dan **Supabase** yang dirancang untuk mempercepat pelaporan kerusakan infrastruktur publik, pemeliharaan lingkungan, dan fasilitas umum di seluruh wilayah Indonesia. 

Dengan memadukan validasi koordinat geospasial presisi, sistem pemantauan status penanganan dua arah (*two-way status tracking*), serta forum diskusi publik komunitas, Laporin menghilangkan birokrasi yang rumit dan menghadirkan transparansi penuh bagi seluruh pemangku kepentingan.

```
       [Warga Lapor Masalah] 
                 │
                 ▼
      [Validasi Batas Wilayah GeoJSON] ─── (Di luar RI ditolak)
                 │ (Valid)
                 ▼
     [Supabase Storage & PostgreSQL] 
                 │
                 ├──────────────────────────────┐
                 ▼                              ▼
      [FCM Push Notifikasi]           [Feed Komunitas Publik]
                 │                              │
                 ▼                              ▼
    [Admin Triage & Verifikasi]       [Upvote & Diskusi Warga]
                 │
                 ▼
  [Pengerjaan & Bukti Selesai Wajib Foto]
                 │
                 ▼
     [Laporan Selesai (Immutable)]
```

---

## ✨ Fitur Utama

### 1. Untuk Warga (Civic Engagement)
- 📍 **Pelaporan Cepat & Geospasial Presisi:** Integrasi deteksi lokasi GPS otomatis dengan verifikasi batas wilayah resmi Indonesia (GeoJSON Boundary) dan pemilihan kategori masalah yang intuitif.
- 📸 **Kompresi & Unggah Multi-Foto:** Unggah bukti visual kerusakan dengan kompresi otomatis untuk efisiensi kuota dan kecepatan pengiriman data.
- ⏱️ **Pelacakan Status Real-Time:** Pantau tahapan penanganan laporan (*Menunggu*, *Diterima*, *Diproses*, *Selesai*, atau *Ditolak*) lengkap dengan catatan petugas dan foto bukti penyelesaian.
- 💬 **Feed Publik & Diskusi Komunitas:** Warga dapat memberikan dukungan (*upvote/downvote*), berdiskusi melalui utas komentar berbalas, serta menyaring laporan berdasarkan kategori dan wilayah.
- 📁 **Manajemen Draf & Laporan Saya:** Kelola draf laporan secara offline dan pantau daftar riwayat seluruh laporan yang pernah diajukan.
- 🔒 **Dual-Party Deletion Protocol:** Warga memegang kendali awal untuk menghapus (*soft-delete*) laporan pribadi sebelum dapat dimusnahkan secara permanen oleh admin.

### 2. Untuk Admin & Petugas (Governance & Triage)
- 📊 **Dashboard Triage Interaktif:** Pantau metrik KPI (Total Masuk, Menunggu, Dalam Proses, Selesai) secara real-time.
- 🗺️ **Penyaringan Regional (Provinsi):** Triage dan delegasi laporan terfokus berdasarkan provinsi penugasan resmi petugas.
- 📷 **Verifikasi Bukti Penyelesaian Wajib:** Perubahan status menjadi `Selesai` mewajibkan unggahan foto hasil pekerjaan lapangan dan catatan resolusi resmi.
- 📢 **Siaran Pengumuman Publik:** Publikasikan maklumat, informasi darurat, atau pemeliharaan berkala langsung ke seluruh warga dan petugas.
- 📈 **Statistik & Analisis Tren:** Visualisasi grafik tren bulanan dan distribusi kategori untuk evaluasi kinerja pelayanan publik.

### 3. Ekosistem Responsif (Desktop & Mobile)
- 📱 **Mobile-First Experience:** Navigasi jempol ergonomis, gestures interaktif, dan kartu laporan berbingkai lembut.
- 🖥️ **Desktop Optimized Layout (> 800px):**
  - **Sidebar Navigasi Permanen (260px):** Akses instan menu utama tanpa drawer tersembunyi.
  - **Split-View Report Detail (2-Kolom):** Kolom kiri menampilkan ringkasan laporan, linimasa progres, dan aksi petugas; kolom kanan menampilkan panel utas diskusi komunitas secara independen.
  - **Grid Metrik Responsif:** Tampilan kartu KPI 4-kolom sejajar dan feed terpusat dengan batas lebar ergonomis (`maxWidth: 760px`).

---

## 🛠️ Arsitektur & Tumpukan Teknologi

Laporin dibangun menggunakan prinsip **Clean & Layered Architecture**:
- **Presentation Layer:** State management reaktif menggunakan **Provider** (`ChangeNotifier`), memisahkan UI murni dengan logika pengontrol.
- **Data & Repository Layer:** Abstraksi data layer untuk konsistensi akses Supabase REST, RPC, dan penyimpanan lokal.
- **Domain Layer:** Model data kuat dengan *sound null safety*, penegakan invarian bisnis, dan validasi status.
- **Core Services:** Layanan tersentralisasi untuk verifikasi batas geospasial (Ray-Casting GeoJSON), FCM push notifications, dan manajemen kompresi media.

| Komponen | Teknologi / Pustaka | Deskripsi |
| :--- | :--- | :--- |
| **Framework** | [Flutter](https://flutter.dev) (SDK ^3.13.2) | Framework UI multi-platform dengan Dart 3 |
| **State Management** | [Provider](https://pub.dev/packages/provider) (^6.1.5) | Pengelolaan *state* aplikasi yang reaktif dan teruji |
| **Backend & Database** | [Supabase](https://supabase.com) (`supabase_flutter: ^2.18.3`) | PostgreSQL, Auth, Realtime WebSockets, Storage, & RLS Policies |
| **Push Notification** | [Firebase Cloud Messaging](https://firebase.google.com) | Notifikasi instan untuk perubahan status & pengumuman |
| **Peta & Geospasial** | [flutter_map](https://pub.dev/packages/flutter_map) & [geolocator](https://pub.dev/packages/geolocator) | Peta OpenStreetMap, geocoding alamat, dan koordinat GPS |
| **Kompresi Gambar** | [image](https://pub.dev/packages/image) & [image_picker](https://pub.dev/packages/image_picker) | Pengambilan kamera/galeri dan optimasi ukuran berkas |
| **Penyimpanan Lokal** | [shared_preferences](https://pub.dev/packages/shared_preferences) | Penyimpanan konfigurasi tema, draf, dan preferensi notifikasi |

---

## 🛡️ Invarian Bisnis & Protokol Keamanan

1. **Dual State Machine:**
   - **Handling Status:** `newReport` ➔ `accepted` ➔ `inProgress` ➔ `completed` / `rejected` / `cancelled`.
   - **Publication State:** `pendingReview` ➔ `published` ➔ `held` ➔ `archived`.
2. **Immutability of Terminal Reports:**
   Laporan dengan status final (`completed` atau `rejected`) bersifat permanen dan **tidak dapat diubah atau diedit kembali oleh warga**, guna menjamin validitas rekam jejak hukum.
3. **Dual-Party Deletion Protocol:**
   Penghapusan permanen dari basis data dan Supabase Storage membutuhkan persetujuan dua pihak: warga melakukan *soft-delete* (`deleted_by_user`), kemudian admin melakukan eksekusi pembersihan permanen (`deleted_by_admin`).
4. **Verifikasi Batas Teritorial Indonesia:**
   Koordinat laporan divalidasi terhadap poligon batas resmi 38 provinsi di Indonesia via algoritma *Ray-Casting GeoJSON*.
5. **Deduplikasi Notifikasi 6-Event:**
   Sistem perpipaan notifikasi mencegah duplikasi pesan status atau pemicu bersamaan dalam jendela toleransi 5 detik baik di tingkat basis data maupun sisi klien.

---

## 📂 Struktur Direktori

```text
laporin/
├── assets/                     # GeoJSON batas wilayah Indonesia, logo, & aset grafis
├── lib/
│   ├── core/                   # Fondasi bersama
│   │   ├── config/             # Rute, batas wilayah, & konfigurasi aplikasi
│   │   ├── errors/             # Penanganan eksepsi & failure classes
│   │   ├── services/           # BoundaryService, FCMService, MediaService
│   │   ├── theme/              # Flat UI Design System (AppColors, AppTypography, AppTheme)
│   │   └── utils/              # Pemformat tanggal, validator teks, & helpers
│   ├── data/                   # Data layer
│   │   ├── models/             # ReportModel, ProfileModel, CommentModel, VoteModel, dll.
│   │   └── repositories/       # ReportRepository, AuthRepository, NotificationRepository, dll.
│   ├── features/               # Modul fitur berbasis domain
│   │   ├── admin/              # Dashboard admin, filter provinsi, penyelesaian & statistik
│   │   ├── auth/               # Autentikasi Supabase & Google OAuth
│   │   ├── create_report/      # Form pelaporan, pemilih peta, & draf
│   │   ├── edit_report/        # Edit laporan aktif dengan proteksi immutability
│   │   ├── feed/               # Feed publik, kartu laporan, & sistem voting
│   │   ├── my_reports/         # Daftar laporan pribadi warga & filter status
│   │   ├── navigation/         # Navigasi responsif (BottomNav, Sidebar Desktop, AppGate)
│   │   ├── notifications/      # Utas notifikasi reaktif & filter preferensi
│   │   ├── profile/            # Profil pengguna & pengaturan identitas
│   │   ├── report_detail/      # Rincian laporan, bukti resolusi, & thread komentar
│   │   └── settings/           # Pengaturan tema (Gelap/Terang), konektivitas, & preferensi
│   └── main.dart               # Titik masuk aplikasi & konfigurasi MultiProvider
├── supabase/
│   └── migrations/             # Migrasi SQL, skema RLS, & PostgreSQL RPC Functions
└── test/                       # 32 berkas uji komprehensif (Unit, Widget, & Integration Tests)
```

---

## 🚀 Panduan Memulai (Getting Started)

### Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi `>= 3.13.2`
- [Dart SDK](https://dart.dev/get-dart) versi `>= 3.1.0`
- Akun dan proyek [Supabase](https://supabase.com)
- Perangkat Android/iOS atau Browser Google Chrome

### Langkah Instalasi

1. **Klon Repositori:**
   ```bash
   git clone https://github.com/username/laporin.git
   cd laporin
   ```

2. **Pasang Dependensi:**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Lingkungan (.env):**
   Salin file `.env.example` menjadi `.env` di direktori *root* proyek:
   ```bash
   cp .env.example .env
   ```
   Buka file `.env` dan lengkapi konfigurasi berikut:
   ```ini
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   WEB_CLIENT=your-google-web-client-id
   ANDROID_CLIENT=your-google-android-client-id
   IOS_CLIENT=your-google-ios-client-id
   ```

4. **Migrasi Basis Data:**
   Terapkan skrip migrasi yang berada di direktori `supabase/migrations/` ke proyek Supabase Anda untuk mengaktifkan tabel, fungsi RPC, dan aturan RLS (Row Level Security).

### Menjalankan Aplikasi

- **Menjalankan di Google Chrome (Web):**
  ```bash
  flutter run -d chrome
  ```
- **Menjalankan di Emulator / Perangkat Android:**
  ```bash
  flutter run -d android
  ```
- **Menjalankan di Simulator iOS:**
  ```bash
  flutter run -d ios
  ```

---

## 🧪 Pengujian & Kualitas Kode

Laporin menerapkan standar rekayasa perangkat lunak yang ketat untuk memastikan keandalan alur kerja pelaporan:

- **Analisis Statis & Linter:**
  ```bash
  flutter analyze
  ```
  *Memastikan kepatuhan terhadap Effective Dart tanpa peringatan (0 errors, 0 warnings).*

- **Menjalankan Seluruh Rangkaian Uji (350+ Tests):**
  ```bash
  flutter test
  ```

- **Menjalankan Pengujian Spesifik:**
  ```bash
  # Uji peran admin dan navigasi
  flutter test test/admin_role_and_navigation_test.dart

  # Uji protokol dual-party deletion
  flutter test test/dual_party_report_deletion_test.dart

  # Uji ekosistem responsif desktop
  flutter test test/admin_desktop_responsive_test.dart
  ```

---

## 🎨 Filosofi Desain UI/UX

Mengacu pada panduan resmi `DESIGN.md`:
- **Modern Flat UI Design:** Menerapkan prinsip Flat UI murni tanpa *drop shadow* (`elevation: 0`) dengan kontras permukaan tegas dan batas mikro 1px (*crisp hairline borders*).
- **Kurvatura Lembut (Rounded Corners):** Sudut membulat 8px, 12px, 16px hingga pill 999px menghadirkan atmosfer aplikasi yang ramah dan modern.
- **Dukungan Adaptif Mode Gelap & Terang:**
  - **Mode Terang:** Kanvas latar `#F8FAFC` dengan kartu permukaan `#FFFFFF` yang bersih dan lapang.
  - **Mode Gelap:** Palet *Neutral Charcoal & Deep Black* (`#0E0E10` & `#1A1A1E`) yang mengeliminasi kelelahan mata.
- **Aksesibilitas Universal:** Memenuhi standar **WCAG 2.2 AA Compliance** dengan kontras teks minimum 4.5:1 dan target sentuh interaktif minimum 48x48 dp.

---

## 🤝 Kontribusi & Lisensi

Kontribusi terbuka untuk pengembangan fitur yang lebih baik:
1. *Fork* repositori ini.
2. Buat *feature branch* baru (`git checkout -b feature/FiturKeren`).
3. Lakukan *commit* perubahan Anda (`git commit -m 'Menambahkan fitur keren'`).
4. Pastikan `flutter test` dan `flutter analyze` berhasil lulus.
5. *Push* ke *branch* (`git push origin feature/FiturKeren`).
6. Ajukan *Pull Request*.

Hak Cipta © 2026 **Laporin Team**. Dirilis di bawah lisensi terbuka untuk kemajuan tata kelola fasilitas publik di Indonesia.
