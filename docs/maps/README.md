# Sistem Peta dan Geospasial Laporin

Dokumen ini menjelaskan arsitektur, teknologi, dan panduan integrasi sistem pemetaan dan geospasial pada aplikasi **Laporin**.

---

## 1. Filosofi & Pendekatan Open-Source

Aplikasi Laporin sepenuhnya mengadopsi stack pemetaan **open-source** modern tanpa ketergantungan pada layanan komersial berbayar (khususnya Google Maps Platform).

### Ketiadaan Ketergantungan Google Maps:
- ❌ **Google Maps Flutter SDK**: Tidak digunakan. Menghilangkan kerentanan platform channel native yang berat dan inkonsistensi rendering.
- ❌ **Google Maps API Key**: Tidak diperlukan. Tidak ada resiko kebocoran key di file client APK/Web.
- ❌ **Google Cloud Billing**: Nol biaya lisensi dan pemakaian API map/places/geocoding.
- ❌ **Google Geocoding & Places API**: Digantikan oleh PostGIS reverse-lookup otoritatif internal dan OpenStreetMap Nominatim secara aman.

---

## 2. Tech Stack Pemetaan

| Kebutuhan | Teknologi | Catatan Implementasi |
| :--- | :--- | :--- |
| **Map Renderer** | `flutter_map` | Fast, lightweight canvas rendering dengan dukungan Slippy Map tiles standar |
| **Tile Provider** | OpenStreetMap (OSM) | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| **GPS Perangkat** | `geolocator` | Mendapatkan koordinat real-time dengan penanganan permission komprehensif |
| **Coordinate Utilities** | `latlong2` | Tipe data koordinat `LatLng`, kalkulasi jarak, dan bounding box |
| **Database Spasial** | PostgreSQL + PostGIS | Geometri teritorial `GEOMETRY(MultiPolygon, 4326)` & index `GIST` |
| **Reverse Lookup** | PostGIS RPC | `detect_province_by_coordinates` otoritatif di sisi backend |

---

## 3. Komponen Peta & UI

Seluruh komponen pemetaan dibangun secara modular, reusable, dan memisahkan state/controller dari lifecycle widget:

1. **`MapConfig`** (`lib/core/config/map_config.dart`):
   - Konfigurasi terpusat untuk tile URL template, User-Agent (`id.laporin.app`), string atribusi OSM, default center Indonesia (`-2.5489, 118.0149`), default zoom (`5.0`), min/max zoom constraints, dan batasan batas wilayah kamera Indonesia.
2. **`LaporinMapView`** (`lib/core/widgets/laporin_map_view.dart`):
   - Wrapper reusable di atas `FlutterMap`. Mendukung custom interactive markers, marker selection callback, user GPS location pulse indicator, interactive zoom controls, center button, polygon layers, loading/empty states, dan kartu preview marker aktif.
3. **`MapLocationPickerScreen`** (`lib/features/create_report/screens/map_location_picker_screen.dart`):
   - Layar pemilih titik laporan interaktif berbasis drag & crosshair pin di tengah layar.
   - Terintegrasi langsung dengan validasi batas wilayah Indonesia (`BoundaryService.isInsideIndonesia`).
   - Menampilkan status realtime: alamat terdeteksi, nama provinsi, badge validasi (valid vs di luar Indonesia), dan tombol konfirmasi yang dinonaktifkan jika koordinat berada di luar NKRI.
4. **`ReportMapViewerScreen`** (`lib/features/report_detail/screens/report_map_viewer_screen.dart`):
   - Layar fullscreen untuk melihat koordinat pasti laporan yang sudah terbit beserta badge kategori, status penanganan, dan alamat lengkap.
5. **`FeedMapScreen`** (`lib/features/feed/screens/feed_map_screen.dart`):
   - Layar penjelajahan laporan publik dalam peta interaktif berbasis bounding box viewport dinamis (`get_reports_in_viewport`). Menampilkan kartu ringkasan saat marker diklik dan navigasi langsung ke detail laporan.

---

## 4. Kepatuhan Atribusi & Tile Policy

Sesuai dengan ketentuan OpenStreetMap Tile Usage Policy:
- **Atribusi Wajib**: Ditampilkan pada sudut kanan bawah setiap viewport peta melalui widget atribusi resmi: `© OpenStreetMap contributors`.
- **User-Agent**: Mengirimkan User-Agent unik aplikasi (`id.laporin.app/1.0.0`) pada header tile request.
- **Efisiensi Jaringan**: Menggunakan cache image bawaan Flutter tanpa bulk-downloading atau tile scraping liar.

---

## 5. Dokumen Terkait

- [Arsitektur Geospasial & PostGIS (GEOSPATIAL.md)](file:///d:/project_dewanto/flutter_app/laporin/docs/maps/GEOSPATIAL.md)
- [Arsitektur Dual Feed & Seleksi Provinsi (FEED.md)](file:///d:/project_dewanto/flutter_app/laporin/docs/maps/FEED.md)
- [Sumber Data & Kebijakan Tile (DATA_SOURCES.md)](file:///d:/project_dewanto/flutter_app/laporin/docs/maps/DATA_SOURCES.md)

