# Sumber Data & Kebijakan Penggunaan Peta Laporin

Dokumen ini mencantumkan atribusi resmi, kebijakan penggunaan penyedia tile, dan sumber data batas wilayah administratif yang digunakan dalam sistem pemetaan Laporin.

---

## 1. Penyedia Tile: OpenStreetMap (OSM)

- **Tile URL Template**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Lisensi Data**: Open Data Commons Open Database License (ODbL) oleh OpenStreetMap Foundation (OSMF).
- **Atribusi Resmi**:
  ```
  © OpenStreetMap contributors
  ```
  Atribusi ini wajib ditampilkan pada setiap antarmuka yang merender peta (di Laporin diwujudkan dalam komponen `LaporinMapView`).

### Kepatuhan terhadap OpenStreetMap Tile Usage Policy:
1. **User-Agent Header**: Setiap request HTTP tile dari aplikasi Laporin menyertakan header User-Agent:
   `User-Agent: id.laporin.app/1.0.0 (flutter_map; contact@laporin.id)`
2. **Tidak Melakukan Bulk Scraping**: Aplikasi tidak mengunduh tile secara massal untuk penyimpanan offline atau prefetch agresif di luar viewport aktif.
3. **Caching**: Mengandalkan mekanisme in-memory / cache image standar bawaan Flutter sesuai instruksi HTTP caching headers dari server OSM.
4. **Kapasitas Server**: Konfigurasi tile diletakkan terpusat pada `MapConfig` (`lib/core/config/map_config.dart`) sehingga mudah dialihkan ke custom tile server, Mapbox, Carto, atau server hosting lokal jika beban aplikasi di produksi melonjak.

---

## 2. Data Batas Wilayah Administratif

Data batas wilayah dan kode daerah di Laporin mengacu pada standar resmi Republik Indonesia:
1. **Kode Provinsi & Nama Resmi**:
   Mengacu pada standar **Badan Pusat Statistik (BPS)** dan **Kementerian Dalam Negeri (Kemendagri)** RI untuk 38 Provinsi di Indonesia (termasuk pemekaran 4 provinsi di Papua: Papua Selatan, Papua Tengah, Papua Pegunungan, dan Papua Barat Daya).
   - Dimodelkan di Flutter: `lib/core/config/indonesia_regions.dart`
   - Disimpan di Database: Tabel `public.regions` (`level = 'province'`)
2. **Batas Geometri Kedaulatan Teritorial (PostGIS)**:
   - Poligon teritorial batas negara (`level = 'country'`, `code = 'ID'`) dimodelkan dengan SRID 4326.
   - Mengelilingi gugus kepulauan terluar Indonesia dan batas daratan resmi dengan negara tetangga:
     - Batas utara: Sabang, Natuna, Miangas.
     - Batas selatan: Pulau Rote, NTT.
     - Batas barat: Pulau Breueh & Weh, Aceh.
     - Batas timur: Garis Meridian 141° BT perbatasan Papua - Papua Nugini.
     - Pengecualian presisi untuk enklave/negara tetangga: Daratan Singapura, Semenanjung Malaysia, Sabah, Sarawak, Brunei Darussalam, dan Timor Leste secara ketat berada di luar poligon NKRI.
3. **Data Batas Darurat / Offline Client**:
   - `lib/core/services/boundary_data.dart`: Menyimpan representasi poligon batas kasar untuk validasi awal di client saat koneksi internet lambat sebelum kueri backend.
   - Otoritas tertinggi tetap berada pada fungsi PostGIS `validate_report_location` dan trigger `trg_reports_sync_location` di database Supabase.

---

## 3. Catatan Audit Ketergantungan Eksternal

| Layanan | Status di Laporin | Alasan |
| :--- | :--- | :--- |
| **Google Maps SDK** | Dihapus / Tidak Digunakan | Mengurangi ukuran APK, menghindari platform channel overhead |
| **Google Maps API Key** | Dihapus / Tidak Digunakan | Menghilangkan resiko kebocoran kredensial |
| **Google Geocoding API** | Dihapus / Digantikan | PostGIS RPC `detect_province_by_coordinates` & OSM Nominatim |
| **Google Places API** | Dihapus / Digantikan | Nominatim search & custom administrative region lookups |
| **Google Cloud Billing** | Dihapus / Tidak Digunakan | 100% biaya lisensi nol |

