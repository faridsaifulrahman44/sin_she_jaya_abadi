# Spec: Penyempurnaan Mockup & Aplikasi — SinShe Jaya Abadi

Tanggal: 2026-05-29
Status: Draft — menunggu review user

---

## 1. Reorganisasi Menu & Navigasi

### 1.1 Bottom Navigation (tetap 5 tab)

```
[Dashboard] [Obat] [Pasien] [Transaksi] [Laporan]
```

Tidak ada perubahan struktur 5 tab.

### 1.2 Manajemen Stok → Tab di dalam halaman Obat

Halaman `Obat` (saat ini halaman daftar obat + filter chips) diubah jadi **halaman dengan tab strip**:

**Tab urutan (kiri ke kanan):**

1. **Obat** — daftar kartu obat, filter chips (Habis/Menipis/Aman/Semua)
2. **Obat Masuk** — riwayat & form input penambahan stok
3. **Obat Keluar** — riwayat & form pengeluaran non-jual
4. **Keterangan Stok Obat** — rename dari "Stok Alert"
5. **Sinkronisasi** — koreksi/audit stok fisik

> Semua tab tetap dalam satu halaman, diakses via `TabBar` horizontal di bawah app bar.

**Rename:**
- `stok_alert_page.dart` → merge ke dalam `obat_page.dart` sebagai tab
- Route `/stok-alert` di-remove, Stok Alert hanya accessible lewat tab

### 1.3 Menu Akuntansi → DIHAPUS

Seluruh menu Akuntansi dihapus dari navigasi dan struktur aplikasi. Tidak ada fitur yang dipindahkan.

---

## 2. Login Page — Desain dari Project Existing

### 2.1 Sumber Referensi

Gunakan persis desain dari file screenshot:
`mockup/screenshot/login_app.jpeg`

Termasuk:
- Logo SinShe besar di bagian atas
- Warna dan layout sesuai screenshot
- Form login (username/email + password + tombol masuk)
- Tidak perlu merujuk ke desain login di `mockup/index.html`

### 2.2 Implementasi

- Halaman login (`login_page.dart`) dipertahankan desainnya sesuai `login_app.jpeg`
- Logo yang digunakan: `logo_sinshe_login.jpeg` atau `logo_sinshe_versi_png.png`
- Tambahkan logo di atas form, ukuran besar (120-160px)
- Background sesuai screenshot

---

## 3. Logo SinShe — Integrasi Aplikasi

### 3.1 File Logo

Sumber:
- `mockup/screenshot/logo_sinshe.jpeg` — logo utama
- `mockup/screenshot/logo_sinshe_login.jpeg` — versi login
- `mockup/screenshot/logo_sinshe_versi_png.png` — versi PNG (prioritas tinggi, quality terbaik)

### 3.2 Tempat Penerapan

| Lokasi | File Logo | Notes |
|--------|-----------|-------|
| Halaman Login | `logo_sinshe_login.jpeg` / `.png` | Ukuran besar, centered |
| Preview Cetak Struk | Hitam putih | Satu desain, lihat Section 4 |
| Hasil Cetak Struk | Hitam putih | Satu desain, lihat Section 4 |
| App Icon (APK) | `logo_sinshe_versi_png.png` | Di-convert ke format icon |
| Splash Screen | `logo_sinshe_versi_png.png` | Saat app launch |
| Dashboard Header (Owner) | Teks "SinShe Jaya Abadi" | Sudah ada, verified |

### 3.3 Rename Global — "Klinik" → "SinShe Jaya Abadi"

**Yang diubah** (semua teks user-facing, BUKAN nama folder project):

- App display name / title → "SinShe Jaya Abadi"
- Teks header/label "Klinik Sin She Jaya Abadi" → tetap atau ubah sesuai preferensi owner
- Semua teks statis yang menyebut "Klinik" di UI
- Nama app di `pubspec.yaml` / `android/app/build.gradle` → "SinShe Jaya Abadi"
- App label di Android manifest → "SinShe Jaya Abadi"

**Yang TIDAK berubah:**
- Nama folder project: tetap `flutter_klinik_starter`
- Nama package/directory structure internal
- Nama variabel/kelas Dart yang pakai "klinik" (kecuali user-facing string)

---

## 4. Struk Thermal Printing — Hitam Putih

### 4.1 Desain Tunggal

Satu desain struk yang digunakan untuk:
- **Preview di screen** (halaman preview cetak)
- **Hasil cetak fisik** (thermal printer)

Tidak ada perbedaan warna — semua menggunakan **hitam putih saja**.

### 4.2 Elemen Struk

Header struk menggunakan **text/ASCII art** atau header teks sederhana, bukan logo berwarna.

Format: Monospace font, border menggunakan karakter `=` `-` `|`.

### 4.3 Warna Struk (CSS/style di kode)

- Background: putih / transparan
- Text: hitam
- Border/separator: hitam solid atau dashed
- Tidak ada warna biru, hijau, merah di struk

---

## 5. Laporan Owner — Pendekatan A (Komprehensif)

### 5.1 Role Access

- **Owner** → bisa akses halaman Laporan dengan semua fitur
- **Admin** → TIDAK punya akses halaman Laporan (bottom nav tidak tampilkan tab Laporan)

### 5.2 Tab Utama

```
[Harian] [Bulanan] [Tahunan]
```

### 5.3 Tab Harian

**Statistik Utama:**
- Total transaksi hari ini (jumlah + nominal)
- Perbandingan dengan kemarin: `↑ Rp X` atau `↓ Rp X` (warna hijau/merah)
- Breakdown: Obat vs Praktek

**Grafik:**
- Grafik penjualan per jam (bar chart, 06:00 - 21:00)

**Daftar:**
- Top 10 Obat Terjual hari ini (rank, nama, jumlah terjual, nominal)

**Operasional:**
- Obat masuk: X item, total nominal
- Obat keluar (non-jual): X item
- Pasien hadir: X orang

**Action:**
- Tombol Export CSV
- Tombol Cetak Thermal (hitam putih)

### 5.4 Tab Bulanan

**Statistik Utama:**
- Total penjualan bulan ini (jumlah transaksi + nominal)
- Rata-rata penjualan per hari
- Perbandingan dengan bulan lalu: `↑/↓ Rp X`

**Grafik:**
- Grafik tren harian sepanjang bulan (bar chart per hari)

**Daftar:**
- Top 10 Obat Terjual bulan ini
- Breakdown: Obat vs Praktek (%)

**Operasional:**
- Total obat masuk bulan ini
- Total obat keluar (non-jual) bulan ini
- Pasien hadir bulan ini: X orang

**Action:**
- Export CSV
- Cetak Thermal

### 5.5 Tab Tahunan

**Statistik Utama:**
- Total penjualan tahun ini
- Perbandingan year-over-year (jika data tersedia)

**Grafik:**
- Grafik tren bulanan (12 bulan)

**Daftar:**
- Top 10 Obat Terjual sepanjang tahun

**Ringkasan Stok:**
- Total item obat di database
- Jumlah obat dengan stok 0 (habis)
- Jumlah obat dengan stok menipis

**Action:**
- Export CSV
- Cetak Thermal

### 5.6 Format Angka & Tanggal

- Nominal: format Indonesia `Rp 1.250.000`
- Tanggal: format `DD Month YYYY` (Indonesia: "25 Mei 2026")
- Grafik: label sumbu X = tanggal/hari, sumbu Y = nominal

---

## 6. Etalase 3 — Alur & Akses

### 6.1 Akses Per Role

| Role | Etalase 1 | Etalase 2 | Etalase 3 |
|------|-----------|-----------|-----------|
| Owner/SinShe | ✅ | ✅ | ✅ |
| Admin/Petugas | ✅ | ✅ | ❌ |

### 6.2 Etalase 3 — Karakteristik

- **Data:** Belum ada di database. Owner input manual: nama obat racikan, deskripsi, foto, stok, harga, satuan.
- **Tampilan Menu Obat:** Tetap tampil sebagai **kartu obat individual** (sama kayak etalase 1 & 2) — jadi owner bisa lihat stok masing-masing racikan.
- **Obat Masuk etalase 3:** Owner input manual (100% oleh owner).
- **Obat Keluar etalase 3:** Owner input manual (100% oleh owner) — expenditure non-jual (rusak, expired, dll).

### 6.3 Alur Transaksi Berdasarkan Jenis Pasien

**Pasien Praktek:**
- Obat yang dipilih: **hanya dari etalase 3**
- Bisa pilih obat satuan (satu racikan)
- Bisa pilih multiple racikan
- Bisa gabungkan beberapa obat etalase 3 dalam satu transaksi
- Boleh juga masukkan biaya konsultasi/praktek

**Pasien Non-Praktek (Konsultasi/Obat saja):**
- Obat yang dipilih: **hanya dari etalase 1 & 2**
- Tidak bisa pilih obat dari etalase 3
- id_pasien: null (atau sesuai aturan transaksi Obat yang sudah ada)

### 6.4 Validasi di Form Transaksi

Saat user pilih jenis transaksi:
```
[Obat] → tampilkan hanya etalase 1 & 2
[Praktek] → tampilkan hanya etalase 3
```

Validasi:
- Jika jenis = "Obat" tapi user coba pilih obat etalase 3 → tolak dengan pesan: "Obat etalase 3 hanya untuk transaksi Praktek."
- Jika jenis = "Praktek" tapi belum pilih pasien → tolak dengan pesan ramah (sesuai aturan existing: id_pasien WAJIB diisi).

---

## 7. Pasien Non-Praktek — Tidak Dicatat

- Pasien yang hanya beli obat (non-praktek) **tidak** perlu dicatat datanya di sistem
- Tidak perlu input ke tabel `pasien`, `kehadiran_pasien`, `kunjungan_pasien`
- Cukup transaksi aja (obat + nominal)
- Ini sudah menjadi perilaku default sistem (id_pasien = null untuk transaksi Obat)

---

## 8. Technical Notes

### 8.1 File yang大概率 berubah

- `lib/pages/obat_page.dart` — tambah TabBar + 5 tab
- `lib/pages/login_page.dart` — update desain sesuai screenshot
- `lib/core/routing/app_router.dart` — remove `/stok-alert` route
- `lib/core/routing/app_route_registry.dart` — update route registry
- `lib/pages/stok_alert_page.dart` — akan di-merge, cek apakah bisa dihapus atau jadi widget dalam TabView
- `lib/core/services/receipt_printer_service.dart` — ubah warna struk ke hitam putih
- `lib/features/laporan/` — overhaul halaman laporan (tab harian/bulanan/tahunan)
- `lib/pages/dashboard_page.dart` — integrate logo SinShe di header
- `pubspec.yaml` / Android config — rename app name
- `android/app/src/main/AndroidManifest.xml` — app label
- `android/app/src/main/res/` — app icon, splash screen

### 8.2 File Logo

Copy dari `mockup/screenshot/` ke `assets/logo/` atau `assets/images/`:
- `logo_sinshe_versi_png.png`
- `logo_sinshe_login.jpeg`

### 8.3 Checklist sebelum implementasi

- [ ] Konfirmasi: apakah `laporan_page.dart` accessible hanya untuk Owner?
- [ ] Konfirmasi: apakah bottom nav untuk Admin tidak menampilkan tab "Laporan"?
- [ ] Konfirmasi: apakah alur transaksi Obat/Praktek sudah benar dengan filter etalase?
- [ ] Konfirmasi: apakah "Sinkronisasi" tab tetap di Manajemen Stok atau dipindahkan?

---

## 9. Ringkasan Perubahan

| No | Perubahan | Status |
|----|-----------|--------|
| 1 | Stok Alert → tab "Keterangan Stok Obat" di Manajemen Stok | ✅ |
| 2 | Tab urutan: Obat Masuk → Obat Keluar → Keterangan Stok Obat → Sinkronisasi | ✅ |
| 3 | Obat Keluar = expenditure non-jual, semua etalase | ✅ |
| 4 | Login: desain dari `login_app.jpeg` + logo SinShe | ✅ |
| 5 | Logo SinShe: login, preview struk, cetak struk, APK, splash | ✅ |
| 6 | Struk: satu desain, hitam putih semua | ✅ |
| 7 | App rename: "SinShe Jaya Abadi" | ✅ |
| 8 | Rename global "klinik" → "SinShe Jaya Abadi" (user-facing) | ✅ |
| 9 | Hapus menu Akuntansi seluruhnya | ✅ |
| 10 | Laporan Owner: Pendekatan A (Harian/Bulanan/Tahunan komprehensif) | ✅ |
| 11 | Admin: tidak punya halaman Laporan | ✅ |
| 12 | Top 10 Obat | ✅ |
| 13 | Etalase 3: hanya Owner akses, transact sebagai racikan | ✅ |
| 14 | Pasien Praktek → etalase 3, Pasien Non-Praktek → etalase 1&2 | ✅ |
| 15 | Pasien non-praktek tidak dicatat datanya | ✅ |
