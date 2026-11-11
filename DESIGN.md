# Laporin — UI/UX Design Specification

> **Dokumen:** `DESIGN.md`  
> **Produk:** Laporin — Platform Pelaporan Masalah Fasilitas & Lingkungan Publik  
> **Arah Desain:** Modern, Rounded & Flat UI Design (Zero Drop Shadow, Crisp Hairline Borders, Adaptive Light & Dark Mode)  
> **Platform Utama:** Mobile (Android & iOS) dan Web Admin Dashboard  
> **Status:** Spesifikasi resmi UI/UX — panduan standar desain antarmuka modern dengan komponen rounded elegan, tampilan Flat UI murni (tanpa drop shadow / 0 elevation), garis tepi tegas (crisp hairline borders), dukungan tema adaptif ganda (Mode Terang & Mode Gelap), serta tata letak yang bersih, intuitif, dan aksesibel.

---

## 1. Visi & Filosofi Desain

Laporin dirancang sebagai platform pelaporan publik yang menjembatani warga dengan pengelola fasilitas publik dan pemerintah daerah. Aplikasi ini menggabungkan **keandalan sistem pelaporan formal** dengan **pengalaman pengguna modern yang ramah, hangat, dan menyenangkan** (*approachable civic-tech*).

Filosofi desain Laporin berakar pada 6 pilar utama:

1. **Modern, Rounded & Human-Centric:**
   - Menggunakan kurvatura sudut yang lembut dan proporsional (*rounded corners* mulai dari 8px, 12px, 16px hingga pill/stadium 999px).
   - Menghilangkan kesan kaku, birokratis, atau intimidatif; menghadirkan antarmuka yang ramah, kontemporer, dan mengundang partisipasi aktif masyarakat.
2. **Kejelasan Visual & Hirarki Bernapas (Visual Clarity & Generous Whitespace):**
   - Struktur informasi tertata dengan ritme vertikal yang lapang dan seimbang.
   - Informasi disajikan dalam kartu-kartu konten terisolasi rapi dengan kontras teks tajam dan tipografi yang nyaman dibaca.
3. **Flat UI Design & Garis Tepi Tegas (Zero Drop Shadow & Crisp Hairline Borders):**
   - Mengadopsi prinsip Flat UI murni tanpa drop shadow atau elevasi blur (`elevation: 0`, `boxShadow: []`).
   - Pemisahan visual antar elemen dibangun melalui kontras permukaan (`#FFFFFF` terhadap kanvas latar `#F8FAFC` pada mode terang, serta `#1E293B` terhadap `#0B1120` pada mode gelap) dan garis tepi mikro tegas (*crisp hairline borders* 1 px solid).
   - Memberikan tampilan yang sangat bersih, modern, tajam, dan performan tanpa distorsi bayangan.
4. **Berbasis Bukti Nyata & Konteks Geospasial:**
   - Dokumentasi foto/video bukti, peta lokasi interaktif, dan riwayat status penanganan transparan merupakan inti dari setiap layar.
   - Peta dan visual media disajikan dalam bingkai melengkung modern (*rounded media containers*).
5. **Aksesibilitas & Keterbacaan Universal (WCAG 2.2 AA Compliance):**
   - Rasio kontras warna tinggi di atas 4.5:1 untuk teks biasa dan 3:1 untuk teks besar serta komponen UI interaktif baik pada Mode Terang maupun Mode Gelap.
   - Status penanganan tidak pernah hanya diwakili oleh warna, melainkan selalu dilengkapi teks semantik dan ikonografi yang deskriptif.
   - Target sentuh minimum 48x48 dp pada seluruh tombol dan kontrol interaktif.
6. **Dukungan Adaptif Mode Gelap & Terang (Adaptive Dual-Theme Experience):**
   - Menyediakan pengalaman visual yang konsisten dan nyaman di mata pengguna kapan pun aplikasi digunakan.
   - Mode Gelap dirancang menggunakan palet Slate-Dark yang elegan, mengeliminasi silau cahaya saat malam hari tanpa mengurangi kejelasan garis batas (hairline borders), kurvatura komponen, maupun hierarki informasi.

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

Seluruh komponen antarmuka menganut prinsip **Flat UI Design** yang konsisten pada **Mode Terang maupun Mode Gelap**: meniadakan seluruh *drop shadow*, *elevation shadow*, dan *glow shadow* (`elevation: 0`). Struktur spasial dan hierarki visual dipertegas menggunakan **crisp hairline borders (1 px solid)** serta kontras permukaan yang bersih (*surface contrast*):
- **Mode Terang:** Kontras permukaan `#FFFFFF` (Surface) terhadap kanvas `#F8FAFC` (Background) dengan garis batas 1 px solid `#E2E8F0` (Slate 200).
- **Mode Gelap:** Kontras permukaan `#1E293B` (Slate 800) terhadap kanvas `#0B1120` (Slate 950) dengan garis batas 1 px solid `#334155` (Slate 700).

```dart
class AppShadows {
  AppShadows._();

  /// Flat UI: No drop shadow (Berlaku untuk Light & Dark Mode)
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

### 3.3 Palet Warna Fungsional & Semantik (Light & Dark Mode)

Palet warna mempertahankan identitas profesional yang dapat dipercaya, dipadukan dengan kontras permukaan terukur untuk chip dan badge agar antarmuka terasa segar, ramah, dan bebas silau di kedua mode tampilan:

| Kategori Token | Token | Mode Terang (Light) | Mode Gelap (Dark) | Peran & Penggunaan |
| :--- | :--- | :---: | :---: | :--- |
| **Brand Primary** | `color.primary` | `#2563EB` *(Blue 600)* | `#3B82F6` *(Blue 500)* | Warna identitas utama, tombol aksi submit, link aktif, border fokus formulir. Dibuat sedikit lebih cerah pada mode gelap untuk kontras WCAG > 5.5:1. |
| | `color.primary-dark` | `#1D4ED8` *(Blue 700)* | `#2563EB` *(Blue 600)* | State hover/pressed pada tombol utama. |
| | `color.primary-light` | `#3B82F6` *(Blue 500)* | `#60A5FA` *(Blue 400)* | Aksen sekunder, indikator progres aktif, fokus ring. |
| | `color.primary-subtle` | `#EFF6FF` *(Blue 50)* | `#1E3A8A` / `0.18 Primary` | Latar pill chip terpilih, latar belakang seleksi aktif. |
| **Netral, Teks & Kanvas** | `color.text-title` | `#0F172A` *(Slate 900)* | `#F8FAFC` *(Slate 50)* | Judul layar utama, heading kartu laporan, label field input. |
| | `color.text-body` | `#334155` *(Slate 700)* | `#CBD5E1` *(Slate 300)* | Teks isi laporan, isi komentar, pesan panduan. |
| | `color.text-muted` | `#64748B` *(Slate 500)* | `#94A3B8` *(Slate 400)* | Waktu relatif, caption lokasi, placeholder text, ikon sekunder. |
| | `color.border` | `#E2E8F0` *(Slate 200)* | `#334155` *(Slate 700)* | Garis pembatas kartu, separator list, border default input (1px hairline). |
| | `color.border-subtle` | `#F1F5F9` *(Slate 100)* | `#1E293B` *(Slate 800)* | Garis pemisah internal antar elemen sekunder. |
| | `color.surface` | `#FFFFFF` *(White)* | `#1E293B` *(Slate 800)* | Latar kartu laporan, container dialog, permukaan modal, navbar, appbar. |
| | `color.surface-elevated` | `#F8FAFC` *(Slate 50)* | `#0F172A` *(Slate 900)* | Latar dalam input field, inner container, media uploader box. |
| | `color.background` | `#F8FAFC` *(Slate 50)* | `#0B1120` *(Slate 950)* | Latar belakang seluruh kanvas layar aplikasi (Scaffold). |
| **Status Semantik** | `color.success` | `#16A34A` *(Emerald 600)* | `#22C55E` *(Emerald 500)* | Status "Selesai", verifikasi disetujui, badge sukses. |
| | `color.success-subtle` | `#DCFCE7` *(Emerald 100)* | `#064E3B` / `0.18 Emerald` | Latar badge pill status selesai. |
| | `color.success-text` | `#15803D` *(Emerald 700)* | `#86EFAC` *(Emerald 300)* | Teks badge status selesai. |
| | `color.warning` | `#D97706` *(Amber 600)* | `#F59E0B` *(Amber 500)* | Status "Dalam Penanganan", laporan dalam antrean review. |
| | `color.warning-subtle` | `#FEF3C7` *(Amber 100)* | `#78350F` / `0.18 Amber` | Latar badge pill status dalam penanganan. |
| | `color.warning-text` | `#B45309` *(Amber 700)* | `#FDE68A` *(Amber 200)* | Teks badge status dalam penanganan. |
| | `color.danger` | `#DC2626` *(Red 600)* | `#EF4444` *(Red 500)* | Status "Ditolak/Dibatalkan", tombol aksi destruktif, alert validasi error. |
| | `color.danger-subtle` | `#FEE2E2` *(Red 100)* | `#7F1D1D` / `0.18 Red` | Latar badge pill status ditolak/dibatalkan. |
| | `color.danger-text` | `#B91C1C` *(Red 700)* | `#FCA5A5` *(Red 300)* | Teks badge status ditolak/dibatalkan. |
| | `color.info` | `#0284C7` *(Sky 600)* | `#38BDF8` *(Sky 400)* | Status "Baru" / "Diterima", pengumuman resmi administrator. |
| | `color.info-subtle` | `#E0F2FE` *(Sky 100)* | `#0C4A6E` / `0.18 Sky` | Latar badge pill status baru/info. |
| | `color.info-text` | `#0369A1` *(Sky 700)* | `#BAE6FD` *(Sky 200)* | Teks badge status baru/info. |

---

### 3.3.1 Arsitektur & Spesifikasi Mode Gelap (Dark Mode Architecture & Luminance Layering)

Mode Gelap pada Laporin didesain dengan teliti untuk kenyamanan visual di lingkungan rendah cahaya tanpa mengorbankan ketegasan estetika Flat UI dan komponen rounded:

1. **Hierarki Luminansi Slate (Luminance Layering):**
   - Menghindari penggunaan warna hitam murni (`#000000`) yang menyebabkan mata cepat lelah dan menimbulkan kontras tajam tak alami (*halation effect*).
   - Menggunakan sistem pelapisan Slate bertingkat:
     - **Tingkat 0 (Kanvas Scaffold / Background):** `#0B1120` (Slate 950) — dasar paling dalam.
     - **Tingkat 1 (Kartu Konten & Modal / Surface):** `#1E293B` (Slate 800) — permukaan kartu, dialog, dan sheet yang tampak terangkat secara visual berkat perbedaan warna netral.
     - **Tingkat 2 (Kotak Input & Inner Containers):** `#0F172A` (Slate 900) — ceruk input form dan container sekunder.
     - **Tingkat 3 (Crisp Hairline Borders):** `#334155` (Slate 700) — batas tepi mikro 1 px tegas yang membingkai seluruh komponen tanpa silau.
2. **Kepatuhan Aksesibilitas WCAG 2.2 AA:**
   - **Teks Judul (`#F8FAFC`):** Rasio kontras **13.8:1** di atas latar `#1E293B` (standar AA minimal 4.5:1).
   - **Teks Tubuh (`#CBD5E1`):** Rasio kontras **8.9:1**.
   - **Teks Muted/Keterangan (`#94A3B8`):** Rasio kontras **4.8:1**.
   - **Brand Primary (`#3B82F6`):** Rasio kontras **5.2:1** terhadap latar kartu gelap.
3. **Formula Badge Status Semantik Terbalik (Inverted Tinted Pills):**
   - Latar belakang badge menggunakan warna status gelap dengan opasitas 18% (`color.withValues(alpha: 0.18)` atau tingkat 900).
   - Border badge menggunakan warna semantik solid tingkat 600/700 selebar 1 px.
   - Teks badge menggunakan warna pastel terang tingkat 200/300 yang menjamin keterbacaan instan dan kontras tinggi.

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

Tombol dirancang ergonomis dengan sudut membulat 12 px (`AppRadius.md`) atau bentuk pill penuh (`StadiumBorder`) untuk tombol floating, dengan adaptasi warna presisi pada kedua mode tampilan:

1. **Primary Button:**
   - **Bentuk:** Rounded rectangle dengan sudut `12 px` (`BorderRadius.circular(12)`).
   - **Latar:** Solid `color.primary` (`#2563EB` pada Light Mode, `#3B82F6` pada Dark Mode).
   - **Teks:** Putih bersih (`#FFFFFF`), `type.body-medium` (Font Weight 600).
   - **Elevasi & Shadow:** Flat UI (`elevation: 0`, tanpa drop shadow di kedua mode).
   - **Target Sentuh:** Tinggi 48 px untuk mobile, padding horizontal 20 px.
   - **State Tekan/Hover:** Transisi warna halus ke `#1D4ED8` (Light) atau `#2563EB` (Dark).
2. **Secondary / Outlined Button:**
   - **Bentuk:** Rounded rectangle `12 px`.
   - **Latar:** `#FFFFFF` (Light) atau `#1E293B` (Dark).
   - **Border:** `1.5 px solid #E2E8F0` (Light) atau `1.5 px solid #334155` (Dark), berubah menjadi `color.primary` saat hover/fokus.
   - **Teks:** `#0F172A` (Light) atau `#F8FAFC` (Dark) dengan Font Weight 600.
   - **Elevasi:** Flat UI (`elevation: 0`, tanpa drop shadow).
3. **Pill Action Button:**
   - **Bentuk:** Stadium Border (`BorderRadius.circular(999)`).
   - Digunakan untuk tombol cepat seperti "Lihat di Peta", "Filter", atau Floating Action Button.
4. **Destructive Button:**
   - **Bentuk:** Rounded rectangle `12 px`.
   - **Latar:** Solid Danger (`#DC2626` / `#EF4444`) dengan teks putih, atau varian lembut berlatar `#FEE2E2` dengan teks `#B91C1C` (Light) / `#7F1D1D` dengan teks `#FCA5A5` (Dark).

```dart
// Contoh Implementasi AppButton adaptif di Flutter:
ElevatedButton(
  style: ElevatedButton.styleFrom(
    elevation: 0,
    backgroundColor: isDark ? const Color(0xFF3B82F6) : AppColors.primary,
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

Formulir dirancang agar pengguna merasa nyaman, jelas, dan percaya diri saat menginput data laporan di kedua kondisi pencahayaan:

1. **Text Field & Multi-Line Area:**
   - **Bentuk:** Rounded rectangle dengan sudut `12 px` (`BorderRadius.circular(12)`).
   - **Latar Belakang:**
     - *Light Mode:* `#FFFFFF` murni (atau `#F8FAFC` dengan transisi ke putih saat fokus).
     - *Dark Mode:* `#0F172A` (Slate 900) ceruk kontras terhadap kartu `#1E293B`.
   - **Border Default:** `1 px solid #CBD5E1` (Light) atau `1 px solid #334155` (Dark).
   - **Border Fokus:** `1.5 px solid #2563EB` (Light) atau `1.5 px solid #3B82F6` (Dark) dengan soft ambient ring.
   - **Border Error:** `1.5 px solid #DC2626` (Light) atau `1.5 px solid #EF4444` (Dark) dengan pesan error di bawah field.
   - **Label Field:** Diletakkan rapi di atas kotak input dengan teks `type.label` berwarna `#0F172A` (Light) atau `#F8FAFC` (Dark), serta tanda bintang merah `*` untuk kolom wajib.
   - **Warna Teks & Placeholder:** Teks input `#0F172A` (Light) / `#F8FAFC` (Dark); placeholder `#64748B` (Light) / `#94A3B8` (Dark).
   - **Padding Internal:** `EdgeInsets.symmetric(horizontal: 16, vertical: 14)`.
2. **Dropdown Selection:**
   - Kotak rounded `12 px` dengan chevron halus dan popup menu melayang beradius `12 px` berlatar `#FFFFFF` (Light) atau `#1E293B` (Dark) dengan hairline border 1 px.
3. **Map Location Picker Container:**
   - Kontainer peta mini dengan sudut melengkung `16 px` (`BorderRadius.circular(16)`), di-clip menggunakan `ClipRRect`.
   - Dilengkapi hairline border `1 px solid #E2E8F0` (Light) atau `1 px solid #334155` (Dark), pin lokasi modern, dan tombol pill rounded "Ubah Titik Lokasi".
4. **Media Uploader Container:**
   - Kotak uploader foto/video beradius `16 px` dengan garis tepi putus-putus (*dashed border*) bertekstur halus dan latar `#F8FAFC` (Light) atau `#0F172A` (Dark).
   - Thumbnail foto hasil unggahan ditampilkan dalam rasio 1:1 atau 16:9 dengan sudut rounded `12 px` (`ClipRRect(borderRadius: BorderRadius.circular(12))`) dan tombol hapus berbentuk lingkaran di sudut kanan atas.

---

### 4.3 Kartu Laporan Modern (`ReportCard`)

Kartu laporan pada feed publik dan daftar laporan pengguna menyajikan data dengan estetika kontemporer yang rapi:

- **Bentuk & Permukaan:**
  - Latar: `#FFFFFF` murni (Light Mode) atau `#1E293B` Slate 800 (Dark Mode).
  - Sudut: **`16 px` (`BorderRadius.circular(16)`)**.
  - Garis Tepi: `1 px solid #E2E8F0` (Light) atau `1 px solid #334155` (Dark).
  - Bayangan: Flat UI (tanpa drop shadow di kedua mode).
  - Margin Antar Kartu: `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`.
  - Padding Konten: `16 px`.
- **Tata Letak & Hierarki:**
  1. **Header Baris Atas:**
     - Kiri: Avatar pelapor berbentuk lingkaran (`BoxShape.circle`, 36x36 dp) + Nama Pelapor (`#0F172A` di Light / `#F8FAFC` di Dark) + Waktu Relatif (`#64748B` di Light / `#94A3B8` di Dark).
     - Kanan: Badge Status Penanganan berbentuk **Pill Kapsul** (`AppRadius.pill`).
  2. **Judul & Kategori:**
     - Tag Kategori berbentuk chip pill mungil (misal: "Jalan & Jembatan", "Sampah").
     - Judul Laporan: 16 px SemiBold (`#0F172A` di Light / `#F8FAFC` di Dark), maksimal 2 baris dengan pemotongan teks elegan.
  3. **Media Gambar / Thumbnail:**
     - Rasio 16:9, lebar penuh di dalam padding kartu.
     - Sudut gambar melengkung halus: **`12 px` (`ClipRRect(borderRadius: BorderRadius.circular(12))`)**.
     - Indikator jumlah foto (misal: "+3 Foto") berbentuk pill gelap transparan di sudut kanan bawah foto.
  4. **Lokasi Kejadian:**
     - Ikon pin lokasi berwarna `color.primary` dan teks alamat ringkas (`#64748B` di Light / `#94A3B8` di Dark) yang terpotong rapi.
  5. **Footer Bar Interaksi:**
     - Tombol Upvote & Downvote: Pill container rounded (`BorderRadius.circular(999)`) dengan angka vote yang jelas. Latar aktif menggunakan `color.primary-subtle` dengan border aksen.
     - Tombol Komentar: Ikon chat rounded dengan counter jumlah diskusi warga.
     - Tombol Share / Menu Aksi: Ikon tombol melingkar yang halus.

---

### 4.4 Badge Status, Kategori & Filter Bar (Rounded Pills & Stadium Shapes)

Menggunakan bentuk kapsul/pill membulat penuh yang modern (*stadium shape* / `BorderRadius.circular(999)`):

- **Badge Status Penanganan (Handling Status Pill):**
  - **Bentuk:** `StadiumBorder()` / `BorderRadius.circular(999)`.
  - **Padding:** `5 px vertical, 12 px horizontal`.
  - **Tipografi:** `11 px SemiBold`.
  - **Varian Semantik Mode Terang (Light Mode):**
    - *Baru / Diterima:* Latar `#E0F2FE`, Teks `#0369A1`, Border `1 px solid #BAE6FD`.
    - *Dalam Penanganan:* Latar `#FEF3C7`, Teks `#B45309`, Border `1 px solid #FDE68A`.
    - *Selesai:* Latar `#DCFCE7`, Teks `#15803D`, Border `1 px solid #BBF7D0`.
    - *Ditolak / Dibatalkan:* Latar `#FEE2E2`, Teks `#B91C1C`, Border `1 px solid #FECACA`.
  - **Varian Semantik Mode Gelap (Dark Mode):**
    - *Baru / Diterima:* Latar `#0C4A6E` / `0.18 Sky`, Teks `#BAE6FD`, Border `1 px solid #0284C7`.
    - *Dalam Penanganan:* Latar `#78350F` / `0.18 Amber`, Teks `#FDE68A`, Border `1 px solid #D97706`.
    - *Selesai:* Latar `#064E3B` / `0.18 Emerald`, Teks `#86EFAC`, Border `1 px solid #059669`.
    - *Ditolak / Dibatalkan:* Latar `#7F1D1D` / `0.18 Red`, Teks `#FCA5A5`, Border `1 px solid #DC2626`.
- **Filter Chips Bar (Kategori & Wilayah):**
  - Baris horizontal yang dapat digeser (*horizontal scrollable chip list*).
  - **Bentuk:** Pill kapsul membulat penuh (`BorderRadius.circular(999)`).
  - **State Tidak Aktif:**
    - *Light Mode:* Latar `#FFFFFF`, Border `1 px solid #E2E8F0`, Teks `#475569`, Flat (0 elevation).
    - *Dark Mode:* Latar `#1E293B`, Border `1 px solid #334155`, Teks `#94A3B8`, Flat (0 elevation).
  - **State Aktif:**
    - *Light Mode:* Latar `#2563EB` (Primary), Border `1.5 px solid #2563EB`, Teks `#FFFFFF`.
    - *Dark Mode:* Latar `#3B82F6` (Primary), Border `1.5 px solid #3B82F6`, Teks `#FFFFFF`.

---

### 4.5 Modals, Dialog Konfirmasi & Bottom Sheet (Rounded Surfaces)

- **Dialog Konfirmasi (misal: Hapus Laporan, Tolak Laporan, Konfirmasi Selesai):**
  - **Bentuk:** Rounded rectangle dengan sudut **`20 px` (`BorderRadius.circular(20)`)**.
  - **Latar & Garis Tepi:**
    - *Light Mode:* `#FFFFFF` murni dengan border tegas `1 px solid #E2E8F0`.
    - *Dark Mode:* `#1E293B` (Slate 800) dengan border tegas `1 px solid #334155`.
  - **Elevasi:** Flat UI (tanpa drop shadow di kedua mode).
  - **Ikon Ilustrasi:** Berada di dalam lingkaran background warna lembut (48x48 dp) di bagian atas dialog.
  - **Tombol Aksi:** Tombol batal (outlined 12 px) dan tombol konfirmasi (solid 12 px) diletakkan bersisian secara proporsional.
- **Bottom Sheet (Mobile):**
  - **Bentuk:** Sudut atas melengkung anggun **`24 px` (`BorderRadius.vertical(top: Radius.circular(24))`)**.
  - **Drag Handle:** Batang indikator sentuh berbentuk pill di bagian tengah atas (`width: 40 px`, `height: 4 px`, `color: #CBD5E1` di Light atau `#475569` di Dark, `borderRadius: circular(4)`).
  - **Latar:** `#FFFFFF` (Light) atau `#1E293B` (Dark).
  - **Pemisah Internal:** Garis 1 px `#E2E8F0` (Light) atau `#334155` (Dark).

---

### 4.6 Peta & Elemen Visual Geospasial

- **Peta Interaktif (OpenStreetMap via `flutter_map`):**
  - Ditampilkan dalam kartu melengkung dengan sudut **`16 px` (`ClipRRect(borderRadius: BorderRadius.circular(16))`)**.
  - Hairline border container: `1 px solid #E2E8F0` (Light) atau `1 px solid #334155` (Dark).
  - Pin penanda (*custom marker*) berbentuk pin tegak lurus konsisten, menampilkan ikon kategori di tengahnya dengan warna kontras tinggi yang mencolok di kedua tema.
  - Floating map controls (tombol reset kompas, tombol lokasi saya GPS) berbentuk lingkaran sempurna (`BoxShape.circle`) dengan latar `#FFFFFF` (Light) atau `#1E293B` (Dark), ikon `color.primary`, 0 elevation, dan border 1 px tegas (`#E2E8F0` di Light / `#334155` di Dark).

---

### 4.7 Avatar Pengguna & Elemen Identitas

- **Foto Profil Pengguna (`UserAvatar`):**
  - Selalu berbentuk **lingkaran sempurna (`BoxShape.circle` / `CircleAvatar`)**.
  - Dilengkapi border halus `1.5 px solid #FFFFFF` (Light) atau `1.5 px solid #1E293B` (Dark) saat berada di atas gambar atau background kontras.
  - Jika foto tidak tersedia, menampilkan inisial pengguna di atas latar belakang warna pastel lembut (Light) atau warna gelap bertransparansi (Dark) dengan teks kontras tinggi.
- **Logo Brand Laporin:**
  - Lingkaran atau squircle membulat (radius 16px) dengan lambang grafis yang ramah dan tepercaya, mempertahankan saturasi warna biru ikonik di kedua mode tampilan.

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

### 8.2 Token Warna Flutter (`lib/core/theme/app_colors.dart`)

```dart
import 'package:flutter/material.dart';

/// Design tokens for colors based on DESIGN.md Section 3.3 (Light & Dark Mode)
class AppColors {
  AppColors._();

  // Brand Primary (Mode Terang)
  static const Color primary = Color(0xFF2563EB); // Blue 600
  static const Color primaryHover = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryStrong = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6); // Blue 500
  static const Color primarySoft = Color(0xFFEFF6FF); // Blue 50
  static const Color primarySubtle = Color(0xFFEFF6FF);
  static const Color accent = Color(0xFF2563EB);

  // Brand Primary (Mode Gelap)
  static const Color darkPrimary = Color(0xFF3B82F6); // Blue 500 (Higher contrast)
  static const Color darkPrimaryHover = Color(0xFF2563EB); // Blue 600
  static const Color darkPrimaryLight = Color(0xFF60A5FA); // Blue 400
  static const Color darkPrimarySoft = Color(0xFF1E3A8A); // Blue 900
  static const Color darkPrimarySubtle = Color(0xFF1E3A8A);

  // Status & Semantics (Mode Terang)
  static const Color success = Color(0xFF16A34A); // Emerald 600
  static const Color successSubtle = Color(0xFFDCFCE7); // Emerald 100
  static const Color successText = Color(0xFF15803D); // Emerald 700

  static const Color warning = Color(0xFFD97706); // Amber 600
  static const Color warningSubtle = Color(0xFFFEF3C7); // Amber 100
  static const Color warningText = Color(0xFFB45309); // Amber 700

  static const Color danger = Color(0xFFDC2626); // Red 600
  static const Color dangerSubtle = Color(0xFFFEE2E2); // Red 100
  static const Color dangerText = Color(0xFFB91C1C); // Red 700

  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoSubtle = Color(0xFFE0F2FE); // Sky 100
  static const Color infoText = Color(0xFF0369A1); // Sky 700

  // Status & Semantics (Mode Gelap)
  static const Color darkSuccess = Color(0xFF22C55E); // Emerald 500
  static const Color darkSuccessSubtle = Color(0xFF064E3B); // Emerald 900
  static const Color darkSuccessText = Color(0xFF86EFAC); // Emerald 300

  static const Color darkWarning = Color(0xFFF59E0B); // Amber 500
  static const Color darkWarningSubtle = Color(0xFF78350F); // Amber 900
  static const Color darkWarningText = Color(0xFFFDE68A); // Amber 200

  static const Color darkDanger = Color(0xFFEF4444); // Red 500
  static const Color darkDangerSubtle = Color(0xFF7F1D1D); // Red 900
  static const Color darkDangerText = Color(0xFFFCA5A5); // Red 300

  static const Color darkInfo = Color(0xFF38BDF8); // Sky 400
  static const Color darkInfoSubtle = Color(0xFF0C4A6E); // Sky 900
  static const Color darkInfoText = Color(0xFFBAE6FD); // Sky 200

  // Neutrals, Text & Surfaces (Mode Terang)
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textTitle = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155); // Slate 700
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color disabled = Color(0xFF94A3B8); // Slate 400

  // Neutrals, Text & Surfaces (Mode Gelap)
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextTitle = Color(0xFFF8FAFC);
  static const Color darkTextBody = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155); // Slate 700 (1px hairline)
  static const Color darkBorderSubtle = Color(0xFF1E293B); // Slate 800
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceElevated = Color(0xFF0F172A); // Slate 900 (Inputs)
  static const Color darkBackground = Color(0xFF0B1120); // Slate 950 (Canvas)
  static const Color darkDisabled = Color(0xFF64748B); // Slate 500

  // Flat UI Design Tokens: Zero drop shadow di kedua mode
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: Offset.zero,
  );

  static const BoxShadow modalShadow = BoxShadow(
    color: Colors.transparent,
    blurRadius: 0,
    offset: Offset.zero,
  );
}
```

---

### 8.3 Konfigurasi Global Theme (`lib/core/theme/app_theme.dart`)

```dart
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Central ThemeData implementation matching DESIGN.md Section 8.2 & 8.3
/// (Modern, Rounded, Friendly & Professional Civic-Tech — Light & Dark Mode)
class AppTheme {
  AppTheme._();

  // ==========================================
  // MODE TERANG (LIGHT THEME)
  // ==========================================
  static ThemeData get lightTheme {
    const borderSide = BorderSide(color: AppColors.border, width: 1.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.danger,
        brightness: Brightness.light,
      ),

      // App Bar: Clean surface, 0 elevation, 1px bottom border
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.pageTitle,
      ),

      // Card Theme: Sudut membulat 16px, background putih, hairline border (Flat UI)
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: borderSide,
        ),
        margin: EdgeInsets.zero,
        color: AppColors.surface,
      ),

      // Elevated & Filled Button Theme: Sudut membulat 12px
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme: Sudut membulat 12px, border 1px solid
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: borderSide,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
        ),
      ),

      // Input Decoration Theme: Sudut membulat 12px, hairline border
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodySecondary,
        labelStyle: AppTextStyles.label,
      ),

      // Dialog & Modal Theme: Sudut membulat 20px, border 1px
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: borderSide,
        ),
        backgroundColor: AppColors.surface,
      ),

      // Bottom Sheet Theme: Sudut atas membulat 24px
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        backgroundColor: AppColors.surface,
      ),

      // Divider Theme: 1 px hairline border
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==========================================
  // MODE GELAP (DARK THEME)
  // ==========================================
  static ThemeData get darkTheme {
    const darkBorderSide = BorderSide(color: AppColors.darkBorder, width: 1.0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        primary: AppColors.darkPrimary,
        surface: AppColors.darkSurface,
        error: AppColors.darkDanger,
        brightness: Brightness.dark,
      ),

      // App Bar: Slate 800 surface, 0 elevation, 1px bottom border
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: AppTextStyles.pageTitle,
      ),

      // Card Theme: Sudut membulat 16px, background Slate 800, hairline border Slate 700 (Flat UI)
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: darkBorderSide,
        ),
        margin: EdgeInsets.zero,
        color: AppColors.darkSurface,
      ),

      // Elevated & Filled Button Theme: Sudut membulat 12px
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Outlined Button Theme: Sudut membulat 12px, border Slate 700 1px solid
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          side: darkBorderSide,
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.darkTextPrimary),
        ),
      ),

      // Input Decoration Theme: Latar Slate 900, sudut membulat 12px, border Slate 700
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: darkBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: darkBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkDanger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.darkDanger, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        labelStyle: TextStyle(color: AppColors.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),

      // Dialog & Modal Theme: Latar Slate 800, sudut membulat 20px, border Slate 700
      dialogTheme: const DialogThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: darkBorderSide,
        ),
        backgroundColor: AppColors.darkSurface,
      ),

      // Bottom Sheet Theme: Sudut atas membulat 24px, latar Slate 800
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        backgroundColor: AppColors.darkSurface,
      ),

      // Divider Theme: 1 px hairline border Slate 700
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
```

---

## 9. Prompt Standar Eksekusi Kode untuk AI Coding Agent / Developer

Gunakan prompt berikut saat menerapkan desain modern rounded dan adaptasi Dark Mode ke dalam kode sumber aplikasi:

```markdown
### INSTRUKSI REFACTOR UI: Modern, Rounded & Dual-Theme (Light & Dark Mode) Design

Kamu adalah Senior Flutter UI/UX Engineer. Tugasmu adalah mengimplementasikan gaya desain MODERN & ROUNDED serta DUKUNGAN ADAPTIF MODE GELAP (DARK MODE) pada antarmuka aplikasi Flutter "Laporin", mengacu penuh pada panduan resmi di DESIGN.md.

#### 1. Tujuan & Karakter Visual
- Terapkan estetika antarmuka yang modern, ramah, dan profesional dengan sudut membulat proporsional (*rounded components*) dan gaya Flat UI murni (tanpa drop shadow, 0 elevation) pada KEDUA mode: Mode Terang (Light) dan Mode Gelap (Dark).
- Ganti sudut siku-siku kaku (0 px) dengan skala radius modern:
  - Tombol standar (`AppButton`, `ElevatedButton`, `OutlinedButton`): `BorderRadius.circular(12)`.
  - Formulir (`TextFormField`, `InputDecorationTheme`, Dropdown): `BorderRadius.circular(12)`.
  - Kartu laporan (`ReportCard`), Modal dialog, Container peta: `BorderRadius.circular(16)`.
  - Badge status & Tag kategori: Bentuk Pill membulat penuh (`BorderRadius.circular(999)` / `StadiumBorder`).
  - Bottom Sheet: Sudut atas membulat `BorderRadius.vertical(top: Radius.circular(24))` dengan drag handle berbentuk pill.
  - Avatar pengguna: Tetap berbentuk lingkaran sempurna (`BoxShape.circle`).

#### 2. Kualitas Visual & Finishing Mode Gelap
- Terapkan hierarki luminansi Slate bertingkat pada Mode Gelap: Kanvas `#0B1120`, Permukaan Kartu `#1E293B`, Inner Input `#0F172A`, dan Hairline Border `#334155`.
- Jaga kontras teks WCAG 2.2 AA (Teks Utama `#F8FAFC`, Teks Bodi `#CBD5E1`, Teks Muted `#94A3B8`).
- Gunakan formula Inverted Tinted Pills untuk badge status di mode gelap (latar semi-transparan dengan teks pastel kontras).
- Gunakan hairline borders tegas 1 px solid untuk batas kartu dan container tanpa menggunakan drop shadow.
- Pastikan seluruh foto thumbnail di dalam kartu di-clip rapi dengan `ClipRRect(borderRadius: BorderRadius.circular(12))`.
- Jaga target tap minimal 48x48 dp pada layar sentuh mobile.

#### 3. Batasan Mutlak
- JANGAN mengubah aturan bisnis, alur kerja navigasi, query geospasial Supabase, atau invariant status produk.
- JANGAN menimbulkan error layout overflow (`RenderFlex overflowed`).
- Jalankan `dart format`, `flutter analyze`, dan `flutter test` setelah perubahan untuk memastikan 0 error dan semua pengujian lulus.
```

---
*Dokumen `DESIGN.md` ini berlaku sebagai acuan desain resmi untuk seluruh pengembang, desainer, dan coding agent pada proyek Laporin.*
