# Laporin --- UI/UX Design Specification

> **Dokumen:** `DESIGN.md`\
> **Produk:** Laporin --- platform pelaporan masalah lingkungan dan
> fasilitas publik\
> **Sumber desain:** UI showcase yang diberikan pengguna\
> **Platform utama:** Aplikasi mobile (iOS/Android) dan dashboard admin
> web\
> **Status:** Spesifikasi desain awal yang diturunkan dari referensi
> visual; nilai ukuran/warna yang tidak terbaca secara pasti ditetapkan
> sebagai token rekomendasi dan dapat disesuaikan saat implementasi.

## 1. Tujuan Desain

Laporin membantu warga melaporkan masalah di lingkungan, mengikuti
perkembangan laporan, berdiskusi, dan memberi dukungan pada laporan yang
relevan. Admin atau petugas menggunakan dashboard untuk memoderasi
laporan, memperbarui status, meninjau bukti, serta menerbitkan
pengumuman.

Prinsip desain:

1.  **Mudah dipahami:** alur pelaporan dibuat bertahap dan label
    menggunakan bahasa Indonesia yang jelas.
2.  **Berbasis bukti dan lokasi:** foto, kategori, lokasi peta,
    deskripsi, dan riwayat status menjadi informasi utama.
3.  **Transparan:** pengguna dapat melihat status dan perkembangan
    penanganan laporan.
4.  **Partisipatif, tetap tertib:** upvote, komentar, dan thread
    mendukung komunitas; tindakan moderasi harus memiliki alasan dan
    jejak audit.
5.  **Konsisten lintas platform:** aplikasi warga dan dashboard admin
    memakai bahasa visual yang sama, dengan pola navigasi sesuai
    konteks.

## 2. Arsitektur Pengalaman

### 2.1 Peran pengguna

  -----------------------------------------------------------------------
  Peran                   Kebutuhan utama         Area utama
  ----------------------- ----------------------- -----------------------
  Pengunjung              Memahami manfaat        Splash / Intro, Login
                          aplikasi dan mulai      
                          masuk/daftar            

  Warga                   Menjelajah laporan,     Beranda, Detail
                          membuat laporan,        Laporan, Buat Laporan,
                          berinteraksi, memantau  Laporan Saya,
                          laporan sendiri         Notifikasi, Pengumuman

  Admin / petugas         Memeriksa laporan       Daftar Laporan Admin,
                          masuk, mengubah status, Kelola Laporan,
                          menolak dengan alasan,  Selesaikan Laporan,
                          menyelesaikan dengan    Tolak Laporan,
                          bukti, mengelola        Dashboard Web
                          pengumuman              

  Moderator               Meninjau laporan yang   Antrean moderasi dan
                          memerlukan pemeriksaan  detail laporan (perlu
                          dan menangani           disediakan sebagai
                          penyalahgunaan          bagian dari
                                                  implementasi)
  -----------------------------------------------------------------------

### 2.2 Navigasi aplikasi mobile

Navigasi utama menggunakan bottom navigation dengan lima item:

-   **Beranda** --- feed laporan publik.
-   **Laporan** --- daftar/penelusuran laporan.
-   **Tombol "+"** --- aksi utama untuk membuat laporan; dibuat lebih
    menonjol dari item lain.
-   **Notifikasi** --- aktivitas dan pembaruan.
-   **Profil** --- identitas, pengaturan, serta akses ke laporan milik
    pengguna.

Tombol tambah sebaiknya tetap mudah dijangkau dengan satu tangan. Pada
halaman sekunder, gunakan tombol kembali di kiri atas dan judul halaman
yang singkat.

### 2.3 Navigasi dashboard web

Sidebar kiri berisi:

-   Dashboard
-   Laporan
-   Pengguna
-   Announcement / Pengumuman
-   Pengaturan

Bagian konten menggunakan header halaman, kartu metrik, panel laporan
terbanyak, dan aktivitas terbaru. Sidebar menandai menu aktif dengan
latar biru-ungu muda.

## 3. Bahasa Visual

### 3.1 Karakter visual

-   Bersih, ramah, ringan, dan berorientasi pada komunitas.
-   Latar putih atau abu-abu kebiruan sangat muda.
-   Biru-ungu sebagai warna aksi utama.
-   Kartu dengan sudut membulat, garis pembatas halus, dan bayangan
    lembut.
-   Ikon sederhana dengan label, bukan ikon tanpa keterangan untuk aksi
    yang tidak umum.
-   Foto laporan ditampilkan cukup besar agar masalah dapat dikenali.

### 3.2 Token warna

Warna di bawah adalah **token rekomendasi** yang meniru karakter
referensi, bukan hasil pengukuran piksel final.

  ------------------------------------------------------------------------
  Token                    Nilai                   Penggunaan
  ------------------------ ----------------------- -----------------------
  `color.primary`          `#596CFF`               Tombol utama, tab
                                                   aktif, link utama

  `color.primary-strong`   `#4858E8`               Tekan/hover tombol
                                                   utama

  `color.primary-soft`     `#EEF0FF`               Latar pilihan aktif,
                                                   badge lembut

  `color.accent`           `#8B70FF`               Aksen ilustrasi dan
                                                   elemen sekunder

  `color.success`          `#35B978`               Status selesai/berhasil

  `color.warning`          `#F4B740`               Perlu perhatian atau
                                                   status menunggu

  `color.danger`           `#F05260`               Penolakan, laporan
                                                   bermasalah, aksi
                                                   destruktif

  `color.info`             `#4F9BE8`               Informasi dan status
                                                   netral

  `color.text-primary`     `#172746`               Judul dan isi penting

  `color.text-secondary`   `#6F7F9B`               Metadata, helper text

  `color.border`           `#E2E8F2`               Border input, divider,
                                                   kartu

  `color.surface`          `#FFFFFF`               Kartu dan bidang konten

  `color.background`       `#F5F7FC`               Latar halaman

  `color.disabled`         `#B8C2D5`               Kontrol nonaktif
  ------------------------------------------------------------------------

**Aturan warna status:** warna tidak boleh menjadi satu-satunya penanda.
Selalu tampilkan teks status dan, jika memungkinkan, ikon yang relevan.

### 3.3 Tipografi

Gunakan font sans-serif yang mudah dibaca. Rekomendasi implementasi:
**Inter** atau font sistem yang setara.

  ------------------------------------------------------------------------------
  Token                     Ukuran rekomendasi Bobot            Penggunaan
  ---------------------- --------------------- ---------------- ----------------
  `type.display`                     30--34 px Bold             Judul intro /
                                                                splash

  `type.page-title`                  22--24 px Bold / Semibold  Judul halaman

  `type.section-title`               16--18 px Semibold         Judul bagian dan
                                                                kartu

  `type.body`                        14--16 px Regular          Deskripsi dan
                                                                isi

  `type.label`                       12--14 px Medium           Label field dan
                                                                tab

  `type.caption`                     11--12 px Regular          Waktu, lokasi,
                                                                jumlah interaksi

  `type.button`                      14--16 px Semibold         Label tombol
  ------------------------------------------------------------------------------

Gunakan line-height sekitar 1,4--1,6 untuk isi. Hindari metadata yang
terlalu kecil; teks penting tetap nyaman dibaca pada layar ponsel.

### 3.4 Spasi dan layout

Gunakan skala berbasis 4 px:

`space-1: 4` · `space-2: 8` · `space-3: 12` · `space-4: 16` ·
`space-5: 20` · `space-6: 24` · `space-8: 32` · `space-10: 40`

-   Padding layar mobile: sekitar 20--24 px.
-   Jarak antarbagian: 20--24 px.
-   Padding kartu: 12--16 px.
-   Jarak antarkartu: 10--14 px.
-   Dashboard web: gunakan grid fleksibel dengan ruang antarkartu yang
    konsisten.

### 3.5 Radius, border, dan elevasi

  ------------------------------------------------------------------------
  Token                            Nilai rekomendasi Penggunaan
  --------------------- ---------------------------- ---------------------
  `radius.sm`                                   8 px Badge kecil, chip

  `radius.md`                                  12 px Input, thumbnail,
                                                     tombol sekunder

  `radius.lg`                                  16 px Kartu laporan

  `radius.xl`                              22--24 px Panel besar dan modal

  `radius.pill`                               999 px Chip dan tombol
                                                     kapsul

  `border.default`              1 px solid `#E2E8F2` Input dan kartu

  `shadow.card`         0 4px 18px rgba(34, 56, 100, Kartu yang terangkat
                                               0.06) 

  `shadow.modal`            0 12px 32px rgba(34, 56, Modal / popover
                                          100, 0.14) 
  ------------------------------------------------------------------------

Gunakan bayangan secara halus. Struktur harus tetap terbaca ketika
bayangan tidak terlihat.

## 4. Komponen UI

### 4.1 Tombol

-   **Primary:** latar `color.primary`, teks putih, radius pill atau 12
    px. Untuk aksi utama seperti Masuk, Kirim Laporan, Simpan,
    Selesaikan, dan Tolak Laporan.
-   **Secondary:** latar putih, border lembut, teks utama.
-   **Tertiary / Text:** tanpa latar, untuk aksi sekunder seperti Lupa
    password.
-   **Destructive:** warna danger dan konfirmasi tambahan jika aksi
    sulit dibatalkan.
-   **Disabled / Loading:** tampilkan state yang jelas; cegah submit
    ganda ketika request sedang diproses.

Tinggi target tombol utama: 48--52 px pada mobile.

### 4.2 Input dan form

-   Label field berada di atas input.
-   Field wajib memakai tanda `*` dan validasi teks yang jelas.
-   Placeholder memberi contoh format, bukan menggantikan label.
-   Password memiliki kontrol tampil/sembunyi.
-   Error muncul dekat field yang bermasalah.
-   Saat submit gagal, pertahankan data yang sudah diisi.
-   Gunakan dropdown untuk kategori dan pemilih lokasi/peta untuk
    koordinat.

### 4.3 Kartu laporan

Setiap kartu laporan pada feed dan daftar admin dapat menampilkan:

1.  Thumbnail foto (jika tersedia).
2.  Judul laporan maksimal sekitar 2 baris.
3.  Kategori sebagai chip.
4.  Lokasi ringkas.
5.  Waktu relatif (mis. "2 jam lalu").
6.  Status publikasi/penanganan jika relevan.
7.  Jumlah upvote dan komentar.

Thumbnail menggunakan rasio konsisten dan `cover`; gambar gagal dimuat
harus memiliki placeholder. Area kartu dapat dibuka untuk melihat
detail, tetapi kontrol upvote dan komentar harus memiliki target sentuh
sendiri.

### 4.4 Badge, chip, dan tab

-   Chip kategori memakai latar pastel dan teks kontras.
-   Status menggunakan warna yang konsisten dengan statusnya.
-   Tab aktif memakai latar lembut atau garis indikator yang jelas.
-   Filter "Semua", "Baru", "Diproses", dan "Selesai" mempertahankan
    pilihan selama pengguna masih berada pada konteks daftar yang sama.

### 4.5 Komponen tambahan

-   **Avatar:** ukuran konsisten; gunakan inisial sebagai fallback.
-   **Timeline status:** node dan garis vertikal dengan status saat ini
    yang menonjol.
-   **Photo picker:** tombol tambah foto, thumbnail, dan aksi hapus/atur
    ulang.
-   **Map picker:** peta, pin lokasi terpilih, dan aksi gunakan lokasi
    saat ini.
-   **Comment composer:** input ringkas dengan tombol kirim; state
    kosong dan loading.
-   **Notification item:** ikon/avatarnya, ringkasan aktivitas, waktu,
    serta indikator belum dibaca.
-   **Empty state:** ilustrasi/ikon sederhana, penjelasan singkat, dan
    satu aksi yang relevan.
-   **Skeleton/loading:** bentuk mendekati konten akhir untuk mengurangi
    pergeseran layout.

## 5. Spesifikasi Layar Mobile

### 5.1 Splash / Intro

**Tujuan:** memperkenalkan manfaat Laporin dan mengarahkan pengguna
untuk masuk.

Elemen: - Ilustrasi kota/lingkungan pada bagian atas. - Logo dan nama
Laporin. - Headline singkat tentang pelaporan masalah lingkungan. -
Penjelasan manfaat dalam 2--3 baris. - Tombol utama "Mulai". - Link
"Masuk" untuk pengguna yang sudah memiliki akun.

Perilaku: - "Mulai" menuju alur login/registrasi. - Ilustrasi dekoratif
tidak boleh menghalangi konten pada layar pendek. - Gunakan safe area
untuk notch dan home indicator.

### 5.2 Login

Elemen: - Logo/ikon Laporin. - Field email atau nomor telepon. - Field
password dengan tombol tampil/sembunyi. - Tombol Masuk. - Pemisah
"atau". - Tombol Masuk dengan Google. - Link Lupa password dan Daftar.

State yang perlu dirancang: - Default, field fokus, validasi gagal,
kredensial salah, loading, dan berhasil. - Berikan pesan yang tidak
membocorkan apakah suatu akun terdaftar jika kebijakan keamanan
mengharuskannya. - OAuth Google harus menunjukkan state proses dan
kegagalan.

### 5.3 Beranda / Feed

Elemen: - Pemilih wilayah di header dan akses profil. - Search bar untuk
kata kunci, kategori, atau lokasi. - Chip kategori (misalnya Jalan &
Infrastruktur, Fasilitas Umum, Kebersihan, Lainnya). - Filter feed:
Terbaru, Populer, Terdekat. - Daftar kartu laporan. - Bottom navigation.

Perilaku: - Search dan filter dapat digunakan bersama dengan aturan yang
konsisten. - State kosong menjelaskan bahwa belum ada laporan yang
cocok. - Feed menggunakan pagination atau infinite scroll dengan
indikator loading. - Feed populer harus memperhitungkan mekanisme
dukungan dan moderasi yang ditetapkan produk, bukan hanya jumlah mentah
tanpa konteks.

### 5.4 Detail Laporan / Thread

Elemen: - Tombol kembali. - Kategori, judul, lokasi, waktu. - Foto utama
dan galeri thumbnail. - Upvote, komentar, simpan, dan bagikan. -
Deskripsi laporan. - Tag kategori/lokasi. - Daftar komentar dan
composer.

Perilaku: - Upvote memiliki state aktif/nonaktif dan jumlah yang
diperbarui secara optimistis hanya jika aman untuk dilakukan. - Cegah
interaksi ganda yang tidak valid pada upvote. - Galeri foto dapat dibuka
dalam tampilan lebih besar. - Komentar menampilkan identitas publik yang
sesuai, waktu, dan tindakan yang tersedia. - Konten yang sedang ditinjau
atau tidak dipublikasikan harus mengikuti kebijakan visibilitas, bukan
otomatis ditampilkan pada feed publik.

### 5.5 Buat Laporan

Field: 1. **Judul laporan** --- wajib. 2. **Kategori** --- wajib. 3.
**Lokasi** --- wajib, melalui peta/pemilihan lokasi. 4. **Deskripsi**
--- wajib, dengan helper text yang mengarahkan pengguna menulis fakta
spesifik. 5. **Lampiran foto** --- opsional, beberapa foto sesuai batas
produk. 6. Tombol **Kirim Laporan**.

Validasi dan UX: - Tampilkan jumlah karakter jika ada batas
judul/deskripsi. - Validasi tipe file dan ukuran sebelum upload;
jelaskan kesalahan secara spesifik. - Tampilkan thumbnail, progres
upload, retry, dan hapus foto. - Minta izin lokasi hanya ketika fitur
lokasi digunakan; sediakan pemilihan manual. - Konfirmasi sebelum
meninggalkan form yang sudah berubah. - Setelah berhasil, tampilkan
konfirmasi dan arahkan ke detail laporan atau Laporan Saya. - Jangan
menganggap laporan langsung tampil ke publik sebelum status publikasinya
menyatakan demikian.

### 5.6 Laporan Saya / Detail status

Elemen: - Ringkasan laporan milik pengguna. - Badge status. - Timeline:
Diterima → Diproses → Dalam Penanganan → Selesai (sesuaikan dengan state
resmi produk). - Detail laporan dan komentar. - Bukti penyelesaian bila
tersedia. - Aksi yang tersedia untuk laporan tersebut.

Perilaku: - Timeline hanya menandai tahapan yang benar-benar tercatat. -
Setiap perubahan status menampilkan waktu dan keterangan bila
tersedia. - Aksi edit hanya ditampilkan selama laporan memenuhi
kebijakan edit terbatas. - Bila laporan diarsipkan, tampilkan status
arsip dan jelaskan dampaknya terhadap interaksi.

### 5.7 Daftar Laporan Admin (mobile / compact)

Elemen: - Tab Semua, Baru, Diproses, Selesai. - Kartu laporan dengan
thumbnail, judul, kategori, lokasi, waktu, status, dan metrik
interaksi. - Filter dan pencarian bila diperlukan.

Perilaku: - Bedakan status penanganan dari status moderasi/publikasi. -
Tampilkan penanda bahwa laporan memerlukan review. - Jangan menyamakan
"belum ditangani" dengan "belum layak dipublikasikan".

### 5.8 Kelola Laporan --- Update Status

Elemen: - Ringkasan laporan dan status saat ini. - Pilihan status yang
sah. - Catatan opsional atau wajib sesuai transisi. - Tombol Simpan.

Perilaku: - Hanya tampilkan transisi yang diizinkan oleh state
machine. - Tampilkan konfirmasi untuk transisi yang berdampak besar. -
Catat pelaku, waktu, status sebelum/sesudah, dan alasan pada audit
log. - Pesan sukses atau gagal harus jelas dan tidak menghilangkan data
input.

### 5.9 Selesaikan Laporan

Elemen: - Ringkasan laporan. - Upload bukti penyelesaian. - Deskripsi
hasil penanganan. - Tombol Selesai.

Perilaku: - Minta bukti sesuai kebijakan operasional; bila bukti wajib,
tombol tidak aktif sebelum bukti valid. - Tampilkan progres upload dan
penanganan kegagalan. - Setelah berhasil, timeline dan notifikasi
pengguna diperbarui.

### 5.10 Tolak Laporan

Elemen: - Penjelasan bahwa laporan akan ditolak. - Field alasan
penolakan. - Tombol Tolak Laporan.

Perilaku: - Alasan harus cukup spesifik dan sopan; hindari pesan yang
menyalahkan pelapor. - Tampilkan dialog konfirmasi sebelum tindakan
final. - Simpan alasan pada catatan moderasi/audit. - Pisahkan penolakan
publikasi dari penolakan penanganan jika kedua konsep ada di domain
produk.

### 5.11 Thread / Komentar

Elemen: - Header laporan. - Komentar dengan avatar, nama tampilan, isi,
waktu, dan jumlah upvote bila tersedia. - Composer di bagian bawah.

Perilaku: - Urutkan komentar dengan aturan yang transparan. - Sediakan
loading, gagal kirim, komentar kosong, dan pagination. - Terapkan
pelaporan komentar serta moderasi bila fitur ini diaktifkan. - Jangan
mengandalkan warna saja untuk menandai komentar admin atau komentar
baru.

### 5.12 Notifikasi

Kategori contoh: - Admin menanggapi laporan. - Ada komentar baru. -
Status laporan berubah. - Ada upvote pada laporan. - Pengumuman baru.

Perilaku: - Bedakan sudah/belum dibaca secara visual dan semantik. -
Ketika diketuk, arahkan ke konteks yang tepat. - Notifikasi push dan
in-app harus konsisten; izin push diminta setelah pengguna memahami
manfaatnya. - Sediakan empty state dan penanganan tautan ke konten yang
tidak lagi tersedia.

### 5.13 Pengumuman

Elemen: - Feed pengumuman. - Chip kategori/jenis pengumuman. - Judul,
ringkasan, tanggal, dan isi lengkap. - Bottom navigation.

Perilaku: - Pengumuman penting dapat diprioritaskan, tetapi jangan
membuat seluruh daftar terasa seperti peringatan. - Tampilkan tanggal
yang jelas dan sumber/penerbit. - Konten lama tetap memiliki konteks
tanggal.

## 6. Spesifikasi Dashboard Web Admin

### 6.1 Kerangka layout

-   Sidebar tetap di kiri pada layar lebar.
-   Header konten menampilkan judul halaman, identitas admin, dan menu
    akun.
-   Area konten menggunakan grid responsif.
-   Pada viewport sempit, sidebar dapat berubah menjadi drawer.
-   Tabel/daftar laporan harus tetap dapat dipakai pada layar kecil;
    prioritaskan kolom inti dan pindahkan detail ke halaman detail.

### 6.2 Dashboard

Kartu metrik yang terlihat pada referensi: - Total Laporan - Selesai -
Dalam Proses

Panel pendukung: - Laporan Terbanyak berdasarkan kategori. - Aktivitas
Terbaru, misalnya laporan baru, status berubah, dan komentar baru.

Panduan: - Sertakan rentang waktu dan definisi metrik. - Persentase
naik/turun harus memiliki pembanding yang jelas. - Gunakan label teks
dan angka; warna tren hanya sebagai penguat. - Hindari grafik dekoratif
tanpa tindakan yang dapat diambil.

### 6.3 Manajemen laporan

Daftar admin idealnya menyediakan: - Pencarian judul/ID. - Filter
kategori, wilayah, tanggal, status penanganan, dan status moderasi. -
Sorting berdasarkan terbaru, prioritas, atau aktivitas. - Akses ke
detail, bukti, histori perubahan, dan tindakan yang diizinkan. - Bulk
action hanya jika ada konfirmasi dan ringkasan dampak.

### 6.4 Pengguna, pengumuman, dan pengaturan

-   **Pengguna:** pencarian, peran, status akun, dan tindakan
    administratif dengan konfirmasi.
-   **Pengumuman:** buat/edit, preview, jadwalkan atau publikasikan,
    arsipkan.
-   **Pengaturan:** konfigurasi kategori, wilayah, batas unggahan, dan
    kebijakan yang memang dapat dikonfigurasi.
-   Perubahan hak akses dan pengaturan kritis harus dicatat pada audit
    log.

## 7. Status, Moderasi, dan Visibilitas

Desain harus memisahkan **status penanganan laporan** dari **status
moderasi/publikasi**. Jangan memakai satu badge untuk mewakili keduanya.

### 7.1 Status penanganan

Status yang dapat ditampilkan, mengikuti transisi resmi backend:

-   **Diterima** --- laporan tercatat.
-   **Diproses** --- laporan sedang ditinjau atau ditindaklanjuti.
-   **Dalam Penanganan** --- pekerjaan penanganan sedang berlangsung.
-   **Selesai** --- tindakan dinyatakan selesai.
-   **Ditolak** --- laporan tidak diterima untuk proses penanganan,
    dengan alasan.
-   **Diarsipkan** --- laporan masuk arsip sesuai kebijakan retensi.

Nama dan transisi final wajib mengikuti state machine produk. UI tidak
boleh mengizinkan transisi yang tidak sah.

### 7.2 Status moderasi/publikasi

Status terpisah yang disarankan:

-   **Menunggu Review**
-   **Dipublikasikan**
-   **Ditinjau / Perlu Perbaikan**
-   **Ditolak Publikasi**
-   **Diarsipkan**

Bila laporan mencapai ambang downvote berbasis persentase, desain harus
menampilkan status **Perlu Review**, bukan otomatis menghapus laporan.
Tampilkan alasan atau indikator review hanya kepada peran yang berhak;
hindari mendorong brigading dengan memperlihatkan ambang internal secara
gamblang kepada publik.

### 7.3 Prinsip UX moderasi

-   Perubahan moderasi memiliki alasan, pelaku, waktu, dan hasil.
-   Pengguna mendapat pesan yang sopan dan sesuai tingkat detail yang
    aman untuk dibagikan.
-   Laporan yang sedang direview memiliki tampilan konsisten di semua
    permukaan.
-   Kebijakan arsip setelah 24 jam harus diimplementasikan dengan aturan
    backend yang jelas; UI menampilkan status arsip ketika berlaku dan
    tidak menyiratkan penghapusan permanen jika data sebenarnya tetap
    tersimpan.
-   Pengeditan laporan terbatas: UI hanya menampilkan aksi edit saat
    diizinkan dan menjelaskan bila laporan tidak lagi dapat diedit.
-   Audit log tidak dapat diubah melalui antarmuka pengguna biasa.

## 8. Alur Pengguna Utama

### 8.1 Membuat laporan

1.  Warga mengetuk tombol `+`.
2.  Mengisi judul, kategori, lokasi, dan deskripsi.
3.  Menambahkan foto bila diperlukan.
4.  Meninjau validasi dan mengetuk Kirim Laporan.
5.  Aplikasi menampilkan hasil submit dan status laporan.
6.  Pengguna dapat membuka detail dan mengikuti perubahan.

### 8.2 Mendukung dan berdiskusi

1.  Warga membuka kartu laporan.
2.  Membaca foto, lokasi, deskripsi, dan status.
3.  Memberi upvote atau menulis komentar.
4.  Melihat jumlah interaksi dan balasan yang diperbarui.
5.  Jika laporan masuk review, UI mengikuti status publikasi yang
    ditetapkan sistem.

### 8.3 Penanganan oleh admin

1.  Admin membuka daftar laporan.
2.  Memfilter laporan baru atau yang memerlukan review.
3.  Memeriksa detail, lokasi, foto, dan histori.
4.  Memilih transisi status yang sah atau melakukan tindakan moderasi.
5.  Mengisi alasan/catatan dan melampirkan bukti bila dibutuhkan.
6.  Menyimpan perubahan; sistem mencatat audit log dan mengirim
    notifikasi yang relevan.

## 9. Responsivitas

### Mobile

-   Desain utama untuk lebar sekitar 360--430 px.
-   Satu kolom untuk feed dan form.
-   Bottom navigation tetap di area aman bawah.
-   Tombol dan kontrol utama memiliki target sentuh ideal sekitar 44 ×
    44 px atau lebih.
-   Konten panjang dapat scroll tanpa mengunci tombol submit secara
    tidak sengaja.

### Tablet

-   Gunakan margin lebih besar dan, jika sesuai, dua kolom untuk panel
    non-form.
-   Form tetap berurutan satu kolom agar mudah dipahami.
-   Bottom navigation atau navigation rail dipilih secara konsisten.

### Web desktop

-   Sidebar dan konten utama menggunakan grid fleksibel.
-   Dashboard dapat memakai beberapa kolom kartu.
-   Batas lebar konten diterapkan agar teks tidak terlalu panjang.
-   Tabel mendukung scroll horizontal atau tampilan ringkas saat ruang
    terbatas.

## 10. Aksesibilitas dan Usability

-   Targetkan WCAG 2.2 AA untuk kontras dan interaksi web.
-   Pastikan kontras teks normal minimal 4.5:1; teks besar minimal 3:1.
-   Semua input memiliki label yang terlihat dan dapat diakses pembaca
    layar.
-   Ikon aksi memiliki accessible label; jangan hanya mengandalkan
    tooltip.
-   Urutan fokus keyboard pada dashboard mengikuti urutan visual.
-   Status dan error disampaikan melalui teks, bukan warna saja.
-   Hormati safe area perangkat dan ukuran teks sistem.
-   Foto laporan yang informatif memiliki deskripsi alternatif yang
    sesuai; gambar dekoratif menggunakan alt kosong.
-   Berikan feedback pada aksi sukses, gagal, loading, dan perubahan
    status.
-   Hindari animasi yang tidak perlu; hormati preferensi reduced motion.

## 11. Konten dan Microcopy

Gunakan bahasa Indonesia yang ringkas, spesifik, dan tidak menyalahkan
pengguna.

Contoh: - Label tombol: **Kirim Laporan**, **Simpan**, **Selesaikan**,
**Tolak Laporan**. - Validasi: "Judul laporan wajib diisi." - Lokasi:
"Pilih lokasi di peta atau gunakan lokasi saat ini." - Upload gagal:
"Foto belum berhasil diunggah. Periksa koneksi lalu coba lagi." - Status
review: "Laporan sedang ditinjau sebelum ditampilkan ke publik." -
Penolakan: "Laporan belum dapat dipublikasikan karena \[alasan\].
Periksa kembali informasi yang diperlukan." - Empty state: "Belum ada
laporan di sini. Coba ubah filter atau buat laporan baru."

Hindari menjanjikan waktu penyelesaian kecuali sistem memiliki SLA yang
benar-benar berlaku.

## 12. State yang Wajib Dirancang

Setiap layar relevan harus mencakup:

-   Default / data berhasil dimuat.
-   Loading atau skeleton.
-   Empty state.
-   Error jaringan dan retry.
-   Validasi form.
-   Tidak memiliki izin / izin ditolak.
-   Upload berjalan, gagal, dan berhasil.
-   Konten tidak ditemukan atau tidak lagi dapat diakses.
-   Akses ditolak berdasarkan peran.
-   State disabled.
-   Konfirmasi aksi destruktif.
-   Perubahan status yang berhasil dan gagal.
-   Status review/arsip bila relevan.

## 13. Panduan Implementasi Flutter

-   Bangun token warna, tipografi, radius, dan spacing sebagai
    `ThemeData` serta konstanta desain terpusat.
-   Buat komponen reusable: `PrimaryButton`, `AppTextField`,
    `StatusChip`, `ReportCard`, `CategoryChip`, `PhotoPicker`,
    `LocationPicker`, `StatusTimeline`, `CommentTile`, dan `EmptyState`.
-   Pisahkan widget presentasi dari state management dan akses data.
-   Gunakan `SafeArea`, dukung ukuran teks dinamis, dan hindari tinggi
    tetap untuk konten yang dapat membesar.
-   Model status sebagai enum/tipe domain, bukan string bebas yang
    tersebar di widget.
-   Gunakan komponen berbeda untuk status penanganan dan status
    moderasi.
-   Tampilkan loading dan error berdasarkan state request yang nyata.
-   Optimalkan thumbnail untuk feed dan muat gambar resolusi besar hanya
    pada detail.
-   Validasi tipe dan ukuran file di klien, lalu validasi ulang di
    backend.
-   Jangan menyimpan kredensial atau mengandalkan validasi klien sebagai
    kontrol keamanan.

## 14. Panduan Implementasi Dashboard Web

-   Gunakan token visual yang sama dengan aplikasi mobile.
-   Gunakan komponen konsisten untuk sidebar, header, KPI card, filter,
    table/list, status chip, dialog konfirmasi, dan toast.
-   Pastikan semua aksi admin bisa dilakukan dengan keyboard.
-   Tampilkan konteks dan dampak sebelum perubahan status atau moderasi.
-   Batasi akses berdasarkan peran di backend; menyembunyikan tombol di
    UI bukan mekanisme otorisasi.
-   Jangan tampilkan data pribadi yang tidak diperlukan untuk tugas
    admin.

## 15. Acceptance Criteria Desain

### Konsistensi visual

-   [ ] Semua halaman memakai token warna, tipografi, spacing, radius,
    dan state komponen yang konsisten.
-   [ ] Status penanganan dan moderasi dibedakan secara visual dan
    semantik.
-   [ ] Semua kartu laporan memiliki hierarki informasi yang konsisten.

### Pelaporan

-   [ ] Field wajib terlihat jelas dan memiliki validasi yang mudah
    dipahami.
-   [ ] Pengguna dapat memilih lokasi manual jika izin lokasi tidak
    diberikan.
-   [ ] Upload foto menunjukkan progres, kegagalan, dan opsi mencoba
    ulang.
-   [ ] Setelah submit, pengguna mendapat konfirmasi dan dapat memeriksa
    status laporan.

### Interaksi dan status

-   [ ] Upvote dan komentar memiliki state aktif/loading/error yang
    sesuai.
-   [ ] Timeline hanya menampilkan peristiwa status yang tercatat.
-   [ ] Aksi edit hanya muncul ketika kebijakan mengizinkan.
-   [ ] Laporan yang memerlukan review tidak otomatis ditampilkan seolah
    sudah dipublikasikan.

### Admin dan moderasi

-   [ ] Admin hanya dapat memilih transisi status yang sah.
-   [ ] Penolakan memiliki alasan dan konfirmasi yang jelas.
-   [ ] Penyelesaian menampilkan kebutuhan bukti sesuai aturan produk.
-   [ ] Perubahan status dan moderasi memiliki jejak audit di backend.
-   [ ] Dashboard menampilkan definisi metrik dan filter yang jelas.

### Aksesibilitas dan ketahanan

-   [ ] Kontras teks memenuhi target WCAG 2.2 AA.
-   [ ] Target sentuh mobile nyaman digunakan.
-   [ ] Semua layar penting memiliki loading, empty, error, dan success
    state.
-   [ ] Layout tetap terbaca pada layar kecil dan saat ukuran teks
    diperbesar.

## 16. Catatan dan Keputusan yang Masih Perlu Divalidasi

1.  Nilai token warna dan ukuran pada dokumen ini adalah baseline
    rekomendasi; validasikan dengan file desain final atau pengukuran
    screenshot.
2.  Tetapkan batas jumlah, ukuran, dan tipe foto pada produk.
3.  Tetapkan kategori dan struktur wilayah yang berlaku.
4.  Finalisasi nama status dan transisi berdasarkan state machine
    backend.
5.  Definisikan dengan tepat bagaimana kebijakan arsip 24 jam bekerja,
    termasuk apakah yang diarsipkan adalah laporan baru, laporan yang
    tidak aktif, atau objek tertentu.
6.  Tentukan apakah ambang downvote berbasis persentase dihitung
    terhadap total suara dan pada minimum jumlah suara tertentu.
7.  Tentukan visibilitas komentar, laporan yang ditinjau, alasan
    penolakan, dan histori status bagi warga, admin, dan publik.
8.  Tentukan apakah dashboard web memakai desain tabel penuh, daftar
    kartu, atau kombinasi sesuai volume data.
9.  Verifikasi perilaku autentikasi Google, pemulihan akun, dan
    kebijakan izin lokasi.

------------------------------------------------------------------------

**Prinsip penutup:** desain harus membuat warga mudah menyampaikan
masalah dan mudah memahami tindak lanjutnya, sementara admin mendapat
alat yang jelas, aman, dan dapat diaudit untuk memproses laporan.
