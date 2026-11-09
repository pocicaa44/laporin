# Arsitektur Geospasial & PostGIS Laporin

Dokumen ini memaparkan implementasi basis data spasial (PostGIS) untuk memvalidasi batas wilayah Negara Kesatuan Republik Indonesia (NKRI) dan fungsi pencarian spasial performa tinggi.

---

## 1. Fondasi Database & Ekstensi

- **Ekstensi**: `postgis` diaktifkan di schema `extensions` / `public`.
- **Sistem Koordinat (Spatial Reference System)**: `SRID 4326` (WGS 84 - Standard Lat/Lng).
- **Tipe Kolom**: `GEOMETRY(Point, 4326)` pada tabel `public.reports` dan `GEOMETRY(MultiPolygon, 4326)` pada tabel `public.regions`.
- **Indeks Spasial**:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_reports_location_point ON public.reports USING gist (location_point);
  CREATE INDEX IF NOT EXISTS idx_regions_geom ON public.regions USING gist (geom);
  ```

---

## 2. MultiPolygon Batas Wilayah NKRI

Tabel `public.regions` menyimpan data batas administratif berjenjang:
- `level = 'country'`: Record `code = 'ID'` menyimpan representasi MultiPolygon teritorial Indonesia.
- `level = 'province'`: 38 Provinsi dengan kode wilayah standar BPS/Kemendagri.

### Cakupan Poligon Kepulauan Indonesia:
Batas teritorial Indonesia dimodelkan dengan 11 ring poligon berpresisi tinggi yang mencakup seluruh pulau utama dan kepulauan terluar:
1. **Sumatera & Kepulauan Sekitarnya**: Dari Sabang (`5.9°N, 95.0°E`) hingga Selat Sunda (`-6.0°S, 106.0°E`).
2. **Kepulauan Riau & Natuna**: Dipotong presisi pada lintang utara `1.20°N` di perbatasan Selat Singapura untuk mengecualikan daratan Singapura (`1.35°N`).
3. **Jawa & Madura**: Dari Anyer hingga Banyuwangi (`-5.8°S` hingga `-8.8°S`).
4. **Kepulauan Nusa Tenggara**: Bali, Lombok, Sumbawa, Flores, Sumba, dan Timor Barat (NTT).
5. **Kalimantan**: Wilayah kedaulatan Indonesia (Kalbar, Kalteng, Kalsel, Kaltim, Kaltara), dibatasi secara tegas di sepanjang perbatasan darat Sarawak dan Sabah.
6. **Sulawesi**: Seluruh jazirah Sulawesi dan pulau-pulau sekitarnya.
7. **Maluku & Maluku Utara**: Halmahera, Ternate, Tidore, Seram, Ambon, Buru.
8. **Maluku Tenggara & Barat Daya**: Kepulauan Kei, Aru, Tanimbar, dan Babar (dibatasi di atas `126.0°E` untuk koordinat selatan agar tidak merambah Timor Leste).
9. **Papua**: Dari perairan barat Papua Barat Daya hingga perbatasan darat Meridian 141° BT dengan Papua Nugini.

---

## 3. Remote Procedure Calls (RPC) PostGIS

Semua validasi lokasi dan kueri geospasial dieksekusi secara native di database:

### A. `is_point_in_indonesia(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION) -> BOOLEAN`
Memeriksa apakah titik `(p_lat, p_lng)` berada di dalam geometri NKRI (`ST_Covers` atau `ST_Intersects`).
- Menolak negara tetangga: Singapura, Malaysia, Brunei, Timor-Leste, PNG.
- Memberikan performa `< 2ms` dengan spatial index GIST.

### B. `detect_province_by_coordinates(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION) -> TABLE`
Mendeteksi provinsi tempat titik berada berdasarkan poligon atau jarak terdekat (`ST_DWithin` / `ST_Distance`).
- Mengembalikan:
  - `province_id UUID`
  - `province_code VARCHAR`
  - `province_name VARCHAR`
  - `is_valid BOOLEAN`
  - `error_message VARCHAR`

### C. `validate_report_location(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION) -> TABLE`
Fungsi validasi resmi sebelum pembuatan/pembaruan laporan. Jika di luar Indonesia, mengembalikan `is_valid: false` dengan pesan seragam:
> `"Lokasi laporan hanya tersedia di wilayah Indonesia."`

### D. `get_reports_in_viewport(p_min_lat, p_min_lng, p_max_lat, p_max_lng, p_limit) -> SETOF reports`
Mengambil laporan terbit (`published` dan non-terminal) yang berada di dalam bounding box peta:
```sql
ST_MakeEnvelope(p_min_lng, p_min_lat, p_max_lng, p_max_lat, 4326)
```
Digunakan oleh layar `FeedMapScreen` untuk visualisasi peta tanpa membebani memori client.

---

## 4. Trigger Keamanan Integritas Data

Integritas koordinat dijaga oleh trigger level-database `trg_reports_sync_location` pada tabel `public.reports`:
1. Setiap kali terjadi `INSERT` atau `UPDATE` koordinat `latitude`/`longitude`:
2. Titik dikonversi ke geometri PostGIS `ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)`.
3. Validasi otomatis dijalankan: jika `is_point_in_indonesia` mengembalikan `false`, operasi dibatalkan seketika (`RAISE EXCEPTION`):
   > `"Lokasi laporan hanya tersedia di wilayah Indonesia."`
4. Menghubungkan secara otomatis foreign key `province_id` dari wilayah yang terdeteksi.

