# Laporin — UI/UX Design Specification

> **Dokumen:** `DESIGN.md`  
> **Produk:** Laporin — Platform Pelaporan Masalah Fasilitas & Lingkungan Publik  
> **Arah Desain:** Modern, Rounded & Flat UI Design (Zero Drop Shadow, Crisp Hairline Borders)  
> **Platform Utama:** Mobile (Android & iOS) dan Web Admin Dashboard  
> **Status:** Spesifikasi resmi UI/UX — panduan standar desain antarmuka modern dengan komponen rounded elegan, tampilan Flat UI murni (tanpa drop shadow / 0 elevation), garis tepi tegas (crisp hairline borders), dan tata letak yang bersih, intuitif, serta aksesibel.

---

## 1. Visi & Filosofi Desain

Laporin dirancang sebagai platform pelaporan publik yang menjembatani warga dengan pengelola fasilitas publik dan pemerintah daerah. Aplikasi ini menggabungkan **keandalan sistem pelaporan formal** dengan **pengalaman pengguna modern yang ramah, hangat, dan menyenangkan** (*approachable civic-tech*).

Filosofi desain Laporin berakar pada 5 pilar utama:

1. **Modern, Rounded & Human-Centric:**
   - Menggunakan kurvatura sudut yang lembut dan proporsional (*rounded corners* mulai dari 8px, 12px, 16px hingga pill/stadium 999px).
   - Menghilangkan kesan kaku, birokratis, atau intimidatif; menghadirkan antarmuka yang ramah, kontemporer, dan mengundang partisipasi aktif masyarakat.
2. **Kejelasan Visual & Hirarki Bernapas (Visual Clarity & Generous Whitespace):**
   - Struktur informasi tertata dengan ritme vertikal yang lapang dan seimbang.
   - Informasi disajikan dalam kartu-kartu konten terisolasi rapi dengan kontras teks tajam dan tipografi yang nyaman dibaca.
3. **Flat UI Design & Garis Tepi Tegas (Zero Drop Shadow & Crisp Hairline Borders):**
   - Mengadopsi prinsip Flat UI murni tanpa drop shadow atau elevasi blur (`elevation: 0`, `boxShadow: []`).
   - Pemisahan visual antar elemen dibangun melalui kontras permukaan (`#FFFFFF` terhadap kanvas latar `#F8FAFC`) dan garis tepi mikro tegas (*hairline borders* 1 px `#E2E8F0`).
   - Memberikan tampilan yang sangat bersih, modern, tajam, dan performan tanpa distorsi bayangan.
4. **Berbasis Bukti Nyata & Konteks Geospasial:**
   - Dokumentasi foto/video bukti, peta lokasi interaktif, dan riwayat status penanganan transparan merupakan inti dari setiap layar.
   - Peta dan visual media disajikan dalam bingkai melengkung modern (*rounded media containers*).
5. **Aksesibilitas & Keterbacaan Universal (WCAG 2.2 AA Compliance):**
   - Rasio kontras warna tinggi di atas 4.5:1 untuk teks biasa dan 3:1 untuk teks besar serta komponen UI interaktif.
   - Status penanganan tidak pernah hanya diwakili oleh warna, melainkan selalu dilengkapi teks semantik dan ikonografi yang deskriptif.
   - Target sentuh minimum 48x48 dp pada seluruh tombol dan kontrol interaktif.

---

## 2. Arsitektur Informasi & Pengalaman Pengguna

### 2.1 Peran Pengguna & Kebutuhan Antarmuka

| Peran | Kebutuhan Utama | Karakter UI & Area Fokus |
| :--- | :--- | :--- |
| **Warga / Pelapor** | Melaporkan masalah dengan cepat (< 1 menit), memantau progres, berdiskusi di thread publik, dan memberikan upvote/downvote. | Mobile-first, kartu laporan dengan sudut membulat 16px, pill filter chips, navigasi jempol yang ergonomis, formulir bertahap terpandu. |
| **Petugas Lapangan** | Meninjau laporan yang ditugaskan, memvalidasi lokasi kejadian di peta, memperbarui status pengerjaan, dan mengunggah foto bukti selesai. | Mobile responsive & web compact, tombol aksi rounded dengan target sentuh besar, dialog status berbasis gesture, formulir bukti yang efisien. |
| **Admin / Moderator** | Triage laporan baru, moderasi konten/komentar, delegasi tugas, penyelesaian/penolakan berbasis alasan, publikasi pengumuman, audit log. | Web Dashboard modern, kartu KPI rounded dengan micro-elevation, tabel data terorganisasi rapi, split-pane layout dengan sudut modern. |

### 2.2 Navigasi Mobile (Modern Floating/Docked Navigation Bar)

Navigasi bawah (*Bottom Navigation Bar*) didesain modern dengan sudut atas membulat halus (`BorderRadius.vertical(top: Radius.circular(20))`) atau docked melayang dengan soft shadow:
- **Beranda:** Feed publik laporan warga (Tab Nasional & Tab Provinsi) dengan filter kategori berbentuk *rounded pills*.
- **Peta / Eksplorasi:** Penelusuran laporan berbasis peta OpenStreetMap interaktif dalam kontainer rounded.
- **Tombol Lapor (+):** Tombol aksi utama (FAB / Center Action Button) berbentuk lingkaran sempurna atau *rounded squircle* (radius 16px) dengan warna `color.primary` kontras dan bayangan ambient berpendar lembut (*glow shadow*).
- **Notifikasi:** Indikator pembaruan status laporan dan interaksi dengan badge pill unread.
- **Profil:** Ringkasan akun, daftar "Laporan Saya", avatar pengguna melingkar, dan pengaturan preferensi.

### 2.3 Navigasi Web Admin (Modern Curved Sidebar & Header)

- **Sidebar Kiri (Lebar 260px):** Latar belakang putih bersih atau slate gelap, dengan item menu berbentuk pill/rounded rectangle (radius 12px) yang memiliki transisi hover halus.
- **Header Atas Melayang:** Menampilkan indikator provinsi aktif, breadcrumb rounded chip, pencarian cepat dengan sudut 12px, dan profil admin.
- **Kartu Metrik KPI:** 4 kartu metrik utama di bagian atas dengan radius 16px, background putih bersih, dan soft ambient shadow.

---

## 3. Sistem Desain: Bahasa Visual Modern & Rounded

### 3.1 Skala Radius Modern (The Rounded System)

Sistem kurvatura sudut dirancang konsisten menggunakan skala modular yang harmonis:

| Token Token | Nilai | Implementasi Flutter | Penggunaan Komponen |
| :--- | :---: | :--- | :--- |
| `AppRadius.xs` | **4 px** | `BorderRadius.circular(4)` | Indikator mikro, garis aksen, handle bar kecil, tooltip. |
| `AppRadius.sm` | **8 px** | `BorderRadius.circular(8)` | Thumbnail foto kecil, badge status kotak rounded, inner container, filter chip mini. |
| `AppRadius.md` | **12 px** | `BorderRadius.circular(12)` | Tombol utama (`AppButton`), Input Text Field, Dropdown, Menu popup, List tile card. |
| `AppRadius.lg` | **16 px** | `BorderRadius.circular(16)` | Kartu laporan (`ReportCard`), Modal dialog konfirmasi, Kotak peta mini, Container uploader media. |
| `AppRadius.xl` | **20 px** | `BorderRadius.circular(20)` | Header banner, Floating action card, Dialog besar. |
| `AppRadius.xxl` | **24 px** | `BorderRadius.circular(24)` | Sudut atas Bottom Sheet (`BorderRadius.vertical(top: Radius.circular(24))`), Hero banner. |
| `AppRadius.pill` / `full` | **999 px** | `BorderRadius.circular(999)` / `StadiumBorder()` | Category filter chips, Pill status badges, Search bar rounded, Tag wilayah, Floating pill buttons. |
| `AppRadius.circle` | **Lingkaran** | `BoxShape.circle` / `CircleAvatar` | Foto profil pengguna (`UserAvatar`), Ikon tombol aksi cepat melingkar, Logo brand. |

---

### 3.2 Sistem Flat UI & Garis Tepi Bersih (Zero Drop Shadow Design)

Seluruh komponen antarmuka menganut prinsip **Flat UI Design** yang konsisten: meniadakan seluruh *drop shadow*, *elevation shadow*, dan *glow shadow* (`elevation: 0`). Struktur spasial dan hierarki visual dipertegas menggunakan **crisp hairline borders (1 px solid #E2E8F0)** serta kontras permukaan yang bersih (*surface contrast*):

```dart
class AppShadows {
  AppShadows._();

  /// Flat UI: No drop shadow
  static const List<BoxShadow> none = [];

  /// Flat UI: Card tanpa drop shadow
  static const List<BoxShadow> card = [];

  /// Flat UI: Komponen floating tanpa drop shadow
  static const List<BoxShadow> floating = [];

  /// Flat UI: Modal dan dialog tanpa drop shadow
  static const List<BoxShadow> modal = [];

  /// Flat UI: Tombol primary tanpa glow shadow
  static const List<BoxShadow> primaryGlow = [];
}
```

---

### 3.3 Palet Warna Fungsional & Semantik

Palet warna mempertahankan identitas profesional yang dapat dipercaya, dipadukan dengan warna latar *soft pastel* untuk chip dan badge agar antarmuka terasa segar dan ramah:

| Kategori Token | Token | Kode Hex | Peran & Penggunaan |
| :--- | :--- | :--- | :--- |
| **Brand Primary** | `color.primary` | `#2563EB` | Warna identitas utama, tombol aksi submit, link aktif, border fokus formulir. |
| | `color.primary-dark` | `#1D4ED8` | State hover/pressed pada tombol utama. |
| | `color.primary-light` | `#3B82F6` | Aksen sekunder, gradien halus, indikator progres aktif. |
| | `color.primary-subtle` | `#EFF6FF` | Latar pill chip terpilih, latar belakang seleksi aktif. |
| **Netral & Teks** | `color.text-title` | `#0F172A` | Judul layar utama, heading kartu laporan, label field input (Slate 900). |
| | `color.text-body` | `#334155` | Teks isi laporan, isi komentar, pesan panduan (Slate 700). |
| | `color.text-muted` | `#64748B` | Waktu relatif, caption lokasi, placeholder text (Slate 500). |
| | `color.border` | `#E2E8F0` | Garis pembatas kartu, separator list, border default input (Slate 200). |
| | `color.border-subtle` | `#F1F5F9` | Garis pemisah internal antar elemen sekunder (Slate 100). |
| | `color.surface` | `#FFFFFF` | Latar kartu laporan, container dialog, permukaan modal, navbar. |
| | `color.background` | `#F8FAFC` | Latar belakang seluruh layar aplikasi (Slate 50). |
| **Status Semantik** | `color.success` | `#16A34A` | Status "Selesai", verifikasi disetujui, badge sukses (Emerald 600). |
| | `color.success-subtle` | `#DCFCE7` | Latar badge pill status selesai (Emerald 100). |
| | `color.success-text` | `#15803D` | Teks badge status selesai (Emerald 700). |
| | `color.warning` | `#D97706` | Status "Dalam Penanganan", laporan dalam antrean review (Amber 600). |
| | `color.warning-subtle` | `#FEF3C7` | Latar badge pill status dalam penanganan (Amber 100). |
| | `color.warning-text` | `#B45309` | Teks badge status dalam penanganan (Amber 700). |
| | `color.danger` | `#DC2626` | Status "Ditolak/Dibatalkan", tombol aksi destruktif, alert validasi error (Red 600). |
| | `color.danger-subtle` | `#FEE2E2` | Latar badge pill status ditolak/dibatalkan (Red 100). |
| | `color.danger-text` | `#B91C1C` | Teks badge status ditolak/dibatalkan (Red 700). |
| | `color.info` | `#0284C7` | Status "Baru" / "Diterima", pengumuman resmi administrator (Sky 600). |
| | `color.info-subtle` | `#E0F2FE` | Latar badge pill status baru/info (Sky 100). |
| | `color.info-text` | `#0369A1` | Teks badge status baru/info (Sky 700). |

---

### 3.4 Tipografi Fungsional & Hirarki Modern

Tipografi mengutamakan font modern sans-serif (**Plus Jakarta Sans**, **Inter**, atau **Roboto**) dengan ritme vertikal yang proporsional:

| Token | Ukuran | Weight | Line Height | Penggunaan |
| :--- | :---: | :---: | :---: | :--- |
| `type.h1` | 24 px | Bold (700) | 1.25 | Judul layar utama, angka besar metrik dashboard admin. |
| `type.h2` | 18 px | SemiBold (600) | 1.30 | Judul kartu laporan, heading section formulir. |
| `type.h3` | 16 px | SemiBold (600) | 1.35 | Sub-judul detail, nama pengguna pada komentar dan profil. |
| `type.body-large` | 15 px | Regular (400) | 1.50 | Deskripsi detail laporan, isi pengumuman penting. |
| `type.body-regular` | 14 px | Regular (400) | 1.50 | Deskripsi singkat di kartu feed, isi komentar umum. |
| `type.body-medium` | 14 px | Medium (500) | 1.40 | Nilai field input formulir, teks tombol utama. |
| `type.label` | 12 px | SemiBold (600) | 1.20 | Label field formulir (*clear & readable*), teks chip kategori. |
| `type.badge` | 11 px | SemiBold (600) | 1.20 | Teks di dalam pill badge status penanganan. |
| `type.caption` | 11 px | Regular (400) | 1.30 | Waktu relatif ("20 menit lalu"), koordinat GPS, metadata audit. |

---

### 3.5 Spasi & Grid Modular (8 px System)

Menggunakan skala modular berbasis 4 px / 8 px untuk konsistensi ritme tata letak:
- `AppSpacing.xs`: 4 px | `AppSpacing.sm`: 8 px | `AppSpacing.md`: 12 px | `AppSpacing.lg`: 16 px
- `AppSpacing.xl`: 20 px | `AppSpacing.xxl`: 24 px | `AppSpacing.xxxl`: 32 px
- **Margin Tepi Layar Mobile:** 16 px (standar) atau 20 px (tablet/layar lebar).
- **Gutter Antar Kartu Feed:** 14 px – 16 px dengan padding internal kartu 16 px.

---

## 4. Spesifikasi Komponen UI (Rounded & Modern Components)

### 4.1 Tombol Modern (`AppButton`)

Tombol dirancang ergonomis dengan sudut membulat 12 px (`AppRadius.md`) atau bentuk pill penuh (`StadiumBorder`) untuk tombol floating:

1. **Primary Button:**
   - **Bentuk:** Rounded rectangle dengan sudut `12 px` (`BorderRadius.circular(12)`).
   - **Latar:** Solid `color.primary` (`#2563EB`).
   - **Teks:** Putih bersih (`#FFFFFF`), `type.body-medium` (Font Weight 600).
   - **Elevasi & Shadow:** Flat UI (`elevation: 0`, tanpa drop shadow).
   - **Target Sentuh:** Tinggi 48 px untuk mobile, padding horizontal 20 px.
   - **State Tekan/Hover:** Transisi warna halus ke `#1D4ED8`.
2. **Secondary / Outlined Button:**
   - **Bentuk:** Rounded rectangle `12 px`.
   - **Latar:** `#FFFFFF` murni.
   - **Border:** `1.5 px solid #E2E8F0` (berubah menjadi `color.primary` saat hover/fokus).
   - **Teks:** `#0F172A` (SemiBold).
   - **Elevasi:** Flat UI (`elevation: 0`, tanpa drop shadow).
3. **Pill Action Button:**
   - **Bentuk:** Stadium Border (`BorderRadius.circular(999)`).
   - Digunakan untuk tombol cepat seperti "Lihat di Peta", "Filter", atau Floating Action Button.
4. **Destructive Button:**
   - **Bentuk:** Rounded rectangle `12 px`.
   - **Latar:** `#DC2626` (Solid Danger) dengan teks putih, atau latar `#FEE2E2` dengan teks `#B91C1C`.

```dart
// Contoh Implementasi AppButton di Flutter:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Modern rounded corner
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  ),
  onPressed: onPressed,
  child: Text(label, style: AppTextStyles.buttonMedium),
)
```

---

### 4.2 Formulir & Input Data (Rounded Form Controls)

Formulir dirancang agar pengguna merasa nyaman, jelas, dan percaya diri saat menginput data laporan:

1. **Text Field & Multi-Line Area:**
   - **Bentuk:** Rounded rectangle dengan sudut `12 px` (`BorderRadius.circular(12)`).
   - **Latar Belakang:** `#FFFFFF` (atau `#F8FAFC` dengan transisi ke putih saat fokus).
   - **Border Default:** `1 px solid #CBD5E1`.
   - **Border Fokus:** `1.5 px solid #2563EB` dengan soft ambient glow (`0 0 0 3px rgba(37,99,235,0.12)`).
   - **Border Error:** `1.5 px solid #DC2626` dengan pesan error berwarna merah di bawah field.
   - **Label Field:** Diletakkan rapi di atas kotak input dengan teks `type.label` berwarna `#0F172A` dan tanda bintang merah `*` untuk kolom wajib.
   - **Padding Internal:** `EdgeInsets.symmetric(horizontal: 16, vertical: 14)`.
2. **Dropdown Selection:**
   - Kotak rounded `12 px` dengan ikon chevron yang halus dan menu popup melayang beradius `12 px` + soft shadow.
3. **Map Location Picker Container:**
   - Kontainer peta mini dengan sudut melengkung `16 px` (`BorderRadius.circular(16)`), di-clip menggunakan `ClipRRect`.
   - Dilengkapi hairline border `1 px solid #E2E8F0`, pin lokasi modern, dan tombol pill rounded "Ubah Titik Lokasi".
4. **Media Uploader Container:**
   - Kotak uploader foto/video beradius `16 px` dengan garis tepi putus-putus (*dashed border*) bertekstur halus dan latar `#F8FAFC`.
   - Thumbnail foto hasil unggahan ditampilkan dalam rasio 1:1 atau 16:9 dengan sudut rounded `12 px` (`ClipRRect(borderRadius: BorderRadius.circular(12))`) dan tombol hapus berbentuk lingkaran di sudut kanan atas.

---

### 4.3 Kartu Laporan Modern (`ReportCard`)

Kartu laporan pada feed publik dan daftar laporan pengguna menyajikan data dengan estetika kontemporer yang rapi:

- **Bentuk & Permukaan:**
  - Latar: `#FFFFFF` murni.
  - Sudut: **`16 px` (`BorderRadius.circular(16)`)**.
  - Garis Tepi: `1 px solid #E2E8F0` (tegas dan bersih).
  - Bayangan: Flat UI (tanpa drop shadow).
  - Margin Antar Kartu: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`.
  - Padding Konten: `16 px`.
- **Tata Letak & Hierarki:**
  1. **Header Baris Atas:**
     - Kiri: Avatar pelapor berbentuk lingkaran (`BoxShape.circle`, 36x36 dp) + Nama Pelapor + Waktu Relatif.
     - Kanan: Badge Status Penanganan berbentuk **Pill Kapsul** (`AppRadius.pill`).
  2. **Judul & Kategori:**
     - Tag Kategori berbentuk chip pill mungil (misal: "Jalan & Jembatan", "Sampah").
     - Judul Laporan: 16 px SemiBold (`#0F172A`), maksimal 2 baris dengan pemotongan teks elegan.
  3. **Media Gambar / Thumbnail:**
     - Rasio 16:9, lebar penuh di dalam padding kartu.
     - Sudut gambar melengkung halus: **`12 px` (`ClipRRect(borderRadius: BorderRadius.circular(12))`)**.
     - Indikator jumlah foto (misal: "+3 Foto") berbentuk pill gelap transparan di sudut kanan bawah foto.
  4. **Lokasi Kejadian:**
     - Ikon pin lokasi berwarna `color.primary` dan teks alamat ringkas yang terpotong rapi.
  5. **Footer Bar Interaksi:**
     - Tombol Upvote & Downvote: Pill container rounded (`BorderRadius.circular(999)`) dengan angka vote yang jelas. State aktif diberi warna aksen terang.
     - Tombol Komentar: Ikon chat rounded dengan counter jumlah diskusi warga.
     - Tombol Share / Menu Aksi: Ikon tombol melingkar yang halus.

---

### 4.4 Badge Status, Kategori & Filter Bar (Rounded Pills & Stadium Shapes)

Menggunakan bentuk kapsul/pill membulat penuh yang modern (*stadium shape* / `BorderRadius.circular(999)`):

- **Badge Status Penanganan (Handling Status Pill):**
  - **Bentuk:** `StadiumBorder()` / `BorderRadius.circular(999)`.
  - **Padding:** `5 px vertical, 12 px horizontal`.
  - **Tipografi:** `11 px SemiBold`.
  - **Varian Semantik:**
    - *Baru / Diterima:* Latar `#E0F2FE`, Teks `#0369A1`, Border `1 px solid #BAE6FD`.
    - *Dalam Penanganan:* Latar `#FEF3C7`, Teks `#B45309`, Border `1 px solid #FDE68A`.
    - *Selesai:* Latar `#DCFCE7`, Teks `#15803D`, Border `1 px solid #BBF7D0`.
    - *Ditolak / Dibatalkan:* Latar `#FEE2E2`, Teks `#B91C1C`, Border `1 px solid #FECACA`.
- **Filter Chips Bar (Kategori & Wilayah):**
  - Baris horizontal yang dapat digeser (*horizontal scrollable chip list*).
  - **Bentuk:** Pill kapsul membulat penuh (`BorderRadius.circular(999)`).
  - **State Tidak Aktif:** Latar `#FFFFFF`, Border `1 px solid #E2E8F0`, Teks `#475569`, Flat (tanpa shadow).
  - **State Aktif:** Latar `#2563EB` (Primary), Border `1.5 px solid #2563EB`, Teks `#FFFFFF`, Flat.

---

### 4.5 Modals, Dialog Konfirmasi & Bottom Sheet (Rounded Surfaces)

- **Dialog Konfirmasi (misal: Hapus Laporan, Tolak Laporan, Konfirmasi Selesai):**
  - **Bentuk:** Rounded rectangle dengan sudut **`20 px` (`BorderRadius.circular(20)`)**.
  - **Latar:** `#FFFFFF` murni dengan border tegas `1 px solid #E2E8F0` (Flat UI, tanpa drop shadow).
  - **Ikon Ilustrasi:** Berada di dalam lingkaran background warna lembut (48x48 dp) di bagian atas dialog.
  - **Tombol Aksi:** Tombol batal (outlined 12 px) dan tombol konfirmasi (solid 12 px) diletakkan bersisian secara proporsional.
- **Bottom Sheet (Mobile):**
  - **Bentuk:** Sudut atas melengkung anggun **`24 px` (`BorderRadius.vertical(top: Radius.circular(24))`)**.
  - **Drag Handle:** Batang indikator sentuh berbentuk pill di bagian tengah atas (`width: 40 px`, `height: 4 px`, `color: #CBD5E1`, `borderRadius: circular(4)`).
  - **Latar:** `#FFFFFF` murni.

---

### 4.6 Peta & Elemen Visual Geospasial

- **Peta Interaktif (OpenStreetMap via `flutter_map`):**
  - Ditampilkan dalam kartu melengkung dengan sudut **`16 px` (`ClipRRect(borderRadius: BorderRadius.circular(16))`)**.
  - Pin penanda (*custom marker*) berbentuk pin tegak lurus konsisten, menampilkan ikon kategori di tengahnya.
  - Floating map controls (tombol reset kompas, tombol lokasi saya) berbentuk lingkaran sempurna (`BoxShape.circle`) dengan latar putih, 0 elevation, dan border 1 px tegas.

---

### 4.7 Avatar Pengguna & Elemen Identitas

- **Foto Profil Pengguna (`UserAvatar`):**
  - Selalu berbentuk **lingkaran sempurna (`BoxShape.circle` / `CircleAvatar`)**.
  - Dilengkapi border halus `1.5 px solid #FFFFFF` saat berada di atas gambar atau background kontras.
  - Jika foto tidak tersedia, menampilkan inisial pengguna di atas latar belakang warna pastel dengan teks kontras tinggi.
- **Logo Brand Laporin:**
  - Lingkaran atau squircle membulat (radius 16px) dengan lambang grafis yang ramah dan tepercaya.

---

## 5. Spesifikasi Layar Mobile (User Flow)

### 5.1 Layar Masuk / Login & Registrasi
- **Header:** Logo Laporin melingkar dengan teks sambutan hangat "Selamat Datang di Laporin".
- **Formulir:** Input Email dan Password beradius 12 px dengan ikon awalan (*prefix icon*) monokrom yang elegan.
- **Tombol Masuk:** Tombol Primary lebar penuh, sudut 12 px, dengan efek pendaran biru halus.
- **Pemisah:** Garis tipis bergradasi dengan teks "atau lanjutkan dengan".
- **Social Login:** Tombol "Masuk dengan Google" rounded 12 px berlatar putih dengan border `1 px solid #E2E8F0` dan logo resmi Google.

### 5.2 Beranda / Feed Publik
- **Top Bar:** Header melengkung halus berisi pemilih provinsi (pill chip rounded dengan ikon lokasi), tombol notifikasi ber-badge, dan avatar profil.
- **Tab Bar Navigasi Feed:** Tab pill rounded ("Nasional" dan nama provinsi aktif, misal "DKI Jakarta").
- **Kategori Filter:** Baris chip horizontal berbentuk pill kapsul yang interaktif.
- **Feed List:** Daftar kartu laporan beradius 16 px dengan transisi visual yang mulus saat scroll.
- **Empty State:** Ilustrasi modern bergaya ramah dengan pesan bersahabat dan tombol pill rounded "Buat Laporan Pertama".

### 5.3 Layar Buat Laporan (Form Pelaporan Cepat)
- **Progres Bertahap:** Indikator langkah berupa garis pill membulat.
- **Media Upload:** Kotak upload media dengan sudut rounded 16 px dan tombol kamera/galeri rounded.
- **Input Judul & Deskripsi:** Field input rounded 12 px yang nyaman untuk pengetikan panjang.
- **Kategori:** Grid kartu kecil beradius 12 px dengan ikon ilustratif dan teks kategori yang jelas.
- **Lokasi:** Peta mini rounded 16 px yang langsung mendeteksi koordinat GPS pengguna dengan akurasi tinggi.
- **Bottom Action:** Tombol "Kirim Laporan" rounded 12 px yang terkunci otomatis saat perangkat offline (dilengkapi banner offline rounded).

### 5.4 Layar Detail Laporan & Thread Diskusi
- **Hero Image:** Galeri foto bukti dengan sudut rounded bawah 20 px atau kartu foto melayang 16 px.
- **Status Timeline:** Garis alur vertikal yang menghubungkan node status berbentuk lingkaran berikon status dan kotak catatan petugas beradius 12 px.
- **Interaksi Warga:** Baris voting pill dan tombol share.
- **Thread Komentar:** Kartu komentar beradius 12 px dengan avatar melingkar pelapor/warga dan badge khusus "Petugas/Admin".
- **Composer Komentar:** Input bar rounded menempel di atas keyboard dengan tombol kirim berbentuk lingkaran.

---

## 6. Spesifikasi Dashboard Web Admin

- **Layout Berbasis Kartu Modern:** Seluruh container data menggunakan sudut membulat 16 px dengan background putih bersih dan soft shadow.
- **Tabel Data:** Baris tabel dengan hover effect beradius halus (8 px), sel dengan padding ergonomis, dan badge status berbentuk pill.
- **Modal Tindakan Petugas:**
  - *Modal Selesai:* Mengharuskan lampiran foto bukti penyelesaian dalam uploader rounded 12 px sebelum tombol "Konfirmasi Selesai" aktif.
  - *Modal Tolak:* Pilihan alasan terstruktur dalam dropdown rounded 12 px dan konfirmasi tombol merah rounded 12 px.

---

## 7. Invarian Sistem & Visibilitas Publik (Tetap Terlindungi)

Pembaruan desain visual ke arah **Modern & Rounded** ini **TIDAK MENGUBAH** satu pun aturan keamanan, kontrol akses data, maupun *state machine* backend yang telah ditetapkan dalam `PRD.md` dan `AGENTS.md`:

1. **Dua State Machine Terpisah:**
   - Status Penanganan (`handling_status`): `new`, `accepted`, `in_progress`, `completed`, `rejected`, `cancelled`.
   - Status Publikasi (`publication_state`): `pending_review`, `published`, `held`, `archived`.
   - Keduanya tetap ditampilkan terpisah melalui pill badge semantik yang sesuai.
2. **Aturan Visibilitas Publik:**
   - Laporan HANYA tampil secara publik jika:
     ```sql
     publication_state = 'published' AND handling_status NOT IN ('rejected', 'cancelled')
     ```
3. **Threshold Downvote Otomatis:**
   - Ambang batas downvote aktif (≥70%) secara atomik memindahkan publikasi ke status `held` dan membuat tiket di antrean moderasi admin.
4. **Pencabutan Akses Seketika Saat Terminal:**
   - Laporan yang berstatus `rejected` atau `cancelled` seketika dicabut dari akses publik dan dinonaktifkan seluruh interaksinya (voting/komentar).
5. **Wajib Bukti Foto Penyelesaian:**
   - Perubahan status ke `completed` mutlak membutuhkan bukti foto valid yang diunggah oleh petugas ke Supabase Storage.
6. **Keamanan Role Server-Managed:**
   - Hak istimewa admin dikelola dari sisi server melalui database RLS; client tidak dapat mengubah rolenya sendiri.

---

## 8. Panduan Teknis Implementasi Flutter (Code Guidelines)

### 8.1 Standar Token Radius (`lib/core/theme/app_radius.dart`)

```dart
import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  /// 4 px - Indikator mikro, handle bar kecil, tooltip
  static const double xs = 4.0;
  static const Radius radiusXs = Radius.circular(xs);
  static const BorderRadius borderXs = BorderRadius.all(radiusXs);

  /// 8 px - Thumbnail kecil, inner card, badge kotak rounded
  static const double sm = 8.0;
  static const Radius radiusSm = Radius.circular(sm);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);

  /// 12 px - Tombol standar, text field input, dropdown
  static const double md = 12.0;
  static const Radius radiusMd = Radius.circular(md);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);

  /// 16 px - Kartu laporan, dialog konfirmasi, container uploader media
  static const double lg = 16.0;
  static const Radius radiusLg = Radius.circular(lg);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);

  /// 20 px - Floating banner, action card besar
  static const double xl = 20.0;
  static const Radius radiusXl = Radius.circular(xl);
  static const BorderRadius borderXl = BorderRadius.all(radiusXl);

  /// 24 px - Sudut atas Bottom Sheet
  static const double xxl = 24.0;
  static const Radius radiusXxl = Radius.circular(xxl);
  static const BorderRadius borderXxl = BorderRadius.all(radiusXxl);

  /// 999 px - Filter chip, pill badge status, pill search bar
  static const double pill = 999.0;
  static const Radius radiusPill = Radius.circular(pill);
  static const BorderRadius borderPill = BorderRadius.all(radiusPill);

  /// Stadium border untuk tombol & chip pill
  static const OutlinedBorder stadium = StadiumBorder();
}
```

---

### 8.2 Konfigurasi Global Theme (`lib/core/theme/app_theme.dart`)

```dart
ThemeData get appTheme {
  const borderSide = BorderSide(color: Color(0xFFE2E8F0), width: 1.0);

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    
    // Card Theme: Sudut membulat 16px, background putih bersih, hairline border
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: borderSide,
      ),
      margin: EdgeInsets.zero,
      color: Colors.white,
    ),

    // Elevated & Filled Button Theme: Sudut membulat 12px
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    // Outlined Button Theme: Sudut membulat 12px
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: borderSide,
        foregroundColor: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),

    // Input Decoration Theme: Sudut membulat 12px
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Dialog Theme: Sudut membulat 20px
    dialogTheme: DialogThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: borderSide,
      ),
      backgroundColor: Colors.white,
    ),

    // Bottom Sheet Theme: Sudut atas membulat 24px
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
    ),
  );
}
```

---

## 9. Prompt Standar Eksekusi Kode untuk AI Coding Agent / Developer

Gunakan prompt berikut saat menerapkan desain modern rounded ini ke dalam kode sumber aplikasi:

```markdown
### INSTRUKSI REFACTOR UI: Modern, Rounded & Professional Civic-Tech Design

Kamu adalah Senior Flutter UI/UX Engineer. Tugasmu adalah mengimplementasikan gaya desain MODERN & ROUNDED pada antarmuka aplikasi Flutter "Laporin", mengacu penuh pada panduan resmi di DESIGN.md.

#### 1. Tujuan & Karakter Visual
- Terapkan estetika antarmuka yang modern, ramah, dan profesional dengan sudut membulat proporsional (*rounded components*) dan gaya Flat UI murni (tanpa drop shadow, 0 elevation).
- Ganti sudut siku-siku kaku (0 px) dengan skala radius modern:
  - Tombol standar (`AppButton`, `ElevatedButton`, `OutlinedButton`): `BorderRadius.circular(12)`.
  - Formulir (`TextFormField`, `InputDecorationTheme`, Dropdown): `BorderRadius.circular(12)`.
  - Kartu laporan (`ReportCard`), Modal dialog, Container peta: `BorderRadius.circular(16)`.
  - Badge status & Tag kategori: Bentuk Pill membulat penuh (`BorderRadius.circular(999)` / `StadiumBorder`).
  - Bottom Sheet: Sudut atas membulat `BorderRadius.vertical(top: Radius.circular(24))` dengan drag handle berbentuk pill.
  - Avatar pengguna: Tetap berbentuk lingkaran sempurna (`BoxShape.circle`).

#### 2. Kualitas Visual & Finishing
- Gunakan hairline borders tegas (`1px solid #E2E8F0`) untuk batas kartu dan container tanpa menggunakan drop shadow.
- Pastikan seluruh foto thumbnail di dalam kartu di-clip rapi dengan `ClipRRect(borderRadius: BorderRadius.circular(12))`.
- Jaga target tap minimal 48x48 dp pada layar sentuh mobile.

#### 3. Batasan Mutlak
- JANGAN mengubah aturan bisnis, alur kerja navigasi, query geospasial Supabase, atau invariant status produk.
- JANGAN menimbulkan error layout overflow (`RenderFlex overflowed`).
- Jalankan `dart format`, `flutter analyze`, dan `flutter test` setelah perubahan untuk memastikan 0 error dan semua pengujian lulus.
```

---
*Dokumen `DESIGN.md` ini berlaku sebagai acuan desain resmi untuk seluruh pengembang, desainer, dan coding agent pada proyek Laporin.*
