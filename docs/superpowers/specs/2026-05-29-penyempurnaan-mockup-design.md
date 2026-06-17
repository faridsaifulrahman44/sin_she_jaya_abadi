# Spec: Penyempurnaan Mockup & Aplikasi — SinShe Jaya Abadi

Tanggal: 2026-05-29
Status: Active — berjalan

---

## Ringkasan Decision

| No | Keputusan |
|----|-----------|
| Bottom nav | `[Dashboard] [Riwayat Transaksi] [Akun]` — 3 tab |
| Dashboard | Home base dengan shortcut card ke semua fitur (Obat, Pasien, Transaksi, dll) |
| Menu Obat & Pasien | Accessible dari Dashboard |
| Menu Akuntansi | DIHAPUS seluruhnya |
| Transaksi | Dipindah ke Dashboard (bukan bottom nav), dari Dashboard Owner klik menu "Transaksi" |
| Riwayat Transaksi | Tab 1: Transaksi pasien (praktek & non-praktek). Tab 2: Riwayat restock & obat keluar |
| Print Queue | Ada tabel `print_queue` di DB — mencegah tabrakan cetak |

---

## 1. Navigasi & Struktur Menu

### 1.1 Bottom Navigation — 3 Tab

```
[Dashboard] [Riwayat Transaksi] [Akun]
```

- **Dashboard** → home base, shortcut card ke semua fitur
- **Riwayat Transaksi** → tab transaksi & riwayat stok
- **Akun** → profile, settings, logout, dark mode toggle

### 1.2 Dashboard — Home Base dengan Shortcut Cards + Quick Action

Dashboard Owner (card biru di atas) + grid menu cards + quick action buttons:

```
Card Biru Header:
  - "Halo, SinShe" / "Halo, Owner"
  - "SinShe Jaya Abadi"
  - Jam real-time + tanggal (pojok kanan)
  - Penjualan hari ini: Rp xxx.xxx
  - Tombol dark mode + logout → di halaman Akun

Menu Grid Cards:
  [💊 Obat]         [👥 Pasien]
  [📊 Laporan]     [📅 Jadwal]
  [📦 Stok]

⚡ QUICK ACTION (di bawah menu grid):
  [💊 Jual Obat]    [🏥 Praktek]
  (ETA 1 & 2)      (ETA 3)

NOTIF BAR (di atas quick action):
  "Struk Pending — X" → link ke halaman Print Queue
```

> - Card "Transaksi" DIHAPUS dari menu grid. Transaksi diakses via Quick Action.
> - Menu Obat, Pasien, Stok, Jadwal accessible dari Dashboard.
> - Laporan hanya Owner. Admin tidak melihat card Laporan.
> - Quick Action: "Jual Obat" → form transaksi jenis Obat (ETA 1&2). "Praktek" → form transaksi jenis Praktek (ETA 3).
> - Notif bar "Struk Pending" hanya Owner: badge count transaksi dengan status `pending_print`.

### 1.3 Menu Akuntansi → DIHAPUS

Seluruh menu Akuntansi dihapus. Tidak ada fitur yang dipindahkan.

---

## 2. Riwayat Transaksi — 2 Tab

### 2.1 Tab 1: Transaksi

Daftar transaksi pasien (praktek & non-praktek).

Format per item:
```
[Icon] Nama Pasien / "Tanpa Pasien"
Jenis: Praktek / Obat
Tanggal & Waktu
Nominal: Rp xxx.xxx
Status: Completed / Pending Print
```

Filter chips:
- Semua
- Praktek
- Obat
- Pending Print (Owner only — lihat transaksi yang belum dicetak)

### 2.2 Tab 2: Riwayat Stok

Daftar 2 kategori:

**A. Riwayat Restock (Obat Masuk)**
- Tanggal, nama obat, etalase, jumlah masuk, nominal

**B. Riwayat Obat Keluar (Non-Jual)**
- Tanggal, nama obat, etalase, jumlah keluar, alasan (rusak/kedaluwarsa/hilang)

Filter: Semua | Restock | Obat Keluar

---

## 3. Halaman Transaksi — Flow Lengkap

### 3.1 Akses

- **Owner** → dari Dashboard → klik Quick Action "Jual Obat" atau "Praktek"
- **Admin** → dari Dashboard → klik Quick Action "Jual Obat"

### 3.2 Pilih Jenis Transaksi

```
[Jual Obat]          [Praktek]
```

- **Jual Obat** → hanya tampilkan obat dari **etalase 1 & 2**
- **Praktek** → hanya tampilkan obat dari **etalase 3** (racikan), WAJIB pilih pasien

> Validasi: Jika pilih "Jual Obat" tapi coba pilih obat etalase 3 → tolak dengan pesan: "Obat etalase 3 hanya untuk transaksi Praktek."

### 3.3 Input Transaksi

**Jika Jual Obat:**
- Pilih obat dari eta 1 & 2
- Tambah kuantitas
- Harga otomatis dari `harga_jual` di DB
- id_pasien = null (tidak wajib pilih pasien)
- Metode bayar: Tunai / QRIS

**Jika Praktek:**
- Pilih pasien (WAJIB) — dari daftar pasien
- Owner/SinShe meresepkan obat racikan dari etalase 3
- Owner/SinShe input biaya obat (bisa beda-beda tiap transaksi, sesuai resep)
- Input **biaya konsultasi** (opsional, bisa 0)
- Metode bayar: Tunai / QRIS

### 3.3b Alur Pasien Praktek (di Luar Aplikasi)

> **Catatan penting:** Langkah 1–2 dilakukan **di luar aplikasi** (langsung di klinik).

```
Tahap 1 — Pasien datang
  └── Owner/SinShe terima pasien, tanya gejala

Tahap 2 — Resep
  └── Owner/SinShe tulis resep racikan di kertas nota
       → Racikan: kombinasi obat etalase 3 (bisa satuan atau campuran)
       → Owner/SinShe juga tentukan harga jual racikan per pasien

Tahap 3 — Input di Aplikasi
  └── Admin/petugas buka aplikasi → Form Transaksi
       → Pilih jenis: "Praktek"
       → Pilih pasien dari daftar
       → Input item: racikan sesuai resep Owner
       → Input biaya obat + biaya konsultasi
       → Pilih metode bayar
       → Simpan → print struk → struk diberikan ke pasien
```

### 3.4 Simpan & Notifikasi

Saat klik **"Selesai"**:

```
Data langsung SIMPAN ke database (transaksi + transaksi_item)
├── id_pasien = null (jual obat) atau ID pasien (praktek)
├── status = "pending_print" (Owner) / "completed" (Admin input sendiri)
└── Generate print queue entry

Owner input:
└── Kirim PUSH NOTIFIKASI ke Admin
    → Isi: "Ada struk baru dari [Nama Owner]. Klik untuk cetak."
    → Saat admin klik → masuk halaman Preview Cetak Struk

Admin input:
└── Admin langsung bisa cetak sendiri (tanpa notifikasi ke Owner)
```

### 3.5 Print Queue

Tabel `print_queue` di Supabase:

| Kolom | Tipe | Keterangan |
|-------|------|-----------|
| id | uuid | PK |
| transaksi_id | uuid | FK ke tabel transaksi |
| created_by | uuid | FK ke admin (owner/admin yang input) |
| created_at | timestamptz | Waktu di-queue |
| status | text | `pending` / `printed` / `canceled` |
| printed_by | uuid | FK ke admin yang cetak |
| printed_at | timestamptz | Waktu cetak |

**Flow Print Queue:**
1. Transaksi baru masuk → create queue entry (status: `pending`)
2. Admin/Owner ambil dari queue → tampilkan preview struk
3. Klik cetak → status: `printed`, timestamp recorded
4. Jika batal → status: `canceled`

**Preventing tabrakan:**
- Jika admin sudah klik "Preview" transaksi tertentu → `locked_by` = admin_id, `locked_at` = now
- Entry lain tampil sebagai `locked` (oleh siapa) tapi client lain tidak bisa preview sampai di-release (timeout 5 menit atau manual release)

### 3.6 Preview Cetak Struk

Halaman preview struk:
- Desain: **hitam putih** (satu desain untuk preview + hasil cetak)
- Elemen: header text (bukan logo berwarna), nama klinik, tanggal, item, nominal, footer
- Font: monospace
- Tombol: "Cetak" → kirim ke thermal printer
- Setelah cetak → status: `printed`

---

## 4. Role-Based Access — Ringkasan

### Owner/SinShe

| Fitur | Akses |
|-------|-------|
| Dashboard | ✅ Full (card biru + semua menu) |
| Obat (eta 1, 2, 3) | ✅ Semua |
| Pasien | ✅ Semua |
| Transaksi | ✅ Input + Edit |
| Print | ✅ Bisa cetak sendiri (rare) |
| Laporan | ✅ Full |
| Stok Management | ✅ Semua eta |
| Akun | ✅ Profile, settings, logout |

### Admin/Petugas

| Fitur | Akses |
|-------|-------|
| Dashboard | ✅ Card terbatas (tanpa nominal/laporan) |
| Obat (eta 1, 2) | ✅ Hanya eta 1 & 2 |
| Obat (eta 3) | ❌ |
| Pasien | ✅ Read-only |
| Transaksi | ✅ Input non-praktek + lihat queue |
| Print | ✅ Cetak struk dari queue |
| Laporan | ❌ |
| Stok Management | ✅ Hanya eta 1 & 2 |
| Akun | ✅ Profile, settings, logout |

---

## 5. Etalase 3 — Alur & Akses

### 5.1 Akses Per Role

| Role | Etalase 1 | Etalase 2 | Etalase 3 |
|------|-----------|-----------|-----------|
| Owner/SinShe | ✅ | ✅ | ✅ |
| Admin/Petugas | ✅ | ✅ | ❌ |

### 5.2 Karakteristik Etalase 3

- **Data:** Belum ada di database. Owner input manual: nama racikan, deskripsi, foto, stok, harga.
- **Tampilan menu Obat:** Kartu obat individual (sama kayak eta 1 & 2)
- **Obat Masuk:** 100% oleh Owner
- **Obat Keluar:** 100% oleh Owner

### 5.3 Alur Transaksi

```
[Jual Obat] → hanya eta 1 & 2 → id_pasien = null
[Praktek]   → hanya eta 3     → id_pasien WAJIB
```

Validasi saat transaksi:
- Jika "Jual Obat" tapi pilih obat eta 3 → tolak
- Jika "Praktek" tapi belum pilih pasien → tolak dengan pesan ramah

---

## 6. Login Page

### 6.1 Sumber Referensi

Desain **100% sama persis** dari screenshot: `mockup/screenshot/login_app.jpeg`
- Layout, warna, posisi elemen, spacing, typography — semua mengikuti screenshot
- Satu perubahan: logo di bagian atas di-replace dengan **logo SinShe** (bukan logo yang ada di screenshot asli)

### 6.2 File Logo

Gunakan: `logo_sinshe_versi_png.png` atau `logo_sinshe_login.jpeg`
- Logo SinShe menggantikan logo default yang ada di screenshot
- Ukuran dan positioning mengikuti layout asli screenshot

---

## 7. Logo SinShe — Integrasi Aplikasi

### 7.1 Tempat Penerapan

| Lokasi | File | Notes |
|--------|------|-------|
| Halaman Login | `.png` / `.jpeg` | Logo besar centered |
| Preview Cetak Struk | Teks hitam putih | Header text, bukan logo |
| Hasil Cetak Struk | Teks hitam putih | Satu desain |
| App Icon (APK) | `.png` | Di-convert ke icon format |
| Splash Screen | `.png` | Saat launch |

### 7.2 Rename Global

- App display name → **"SinShe Jaya Abadi"**
- Semua teks user-facing "Klinik" → "SinShe Jaya Abadi"
- Nama folder project → **tetap** `flutter_klinik_starter`

File yang perlu diubah:
- `pubspec.yaml` — name + flutter.app.title
- `android/app/build.gradle` — applicationId / app name
- `android/app/src/main/AndroidManifest.xml` — app label
- `android/app/src/main/res/values/strings.xml` — app name
- Semua teks statis di kode Dart

---

## 8. Struk Thermal Printing — Hitam Putih

### 8.1 Satu Desain

Preview + hasil cetak fisik = sama, hitam putih.

### 8.2 Elemen

- Header: teks "SIN SHE JAYA ABADI" (bold, centered)
- Tanggal & waktu
- No. transaksi
- Item list (nama, qty, harga)
- Subtotal, pajak (jika ada), total
- Metode bayar
- Footer: "Terima Kasih"
- Border: karakter `=` `-` `|` (ASCII)

### 8.3 Font & Warna

- Font: monospace (Courier / JetBrains Mono / built-in monospace)
- Warna: hitam di background putih/transparan
- Tidak ada warna RGB lain

---

## 9. Laporan Owner — Pendekatan A (Komprehensif)

### 9.1 Role Access

- **Owner** → akses penuh
- **Admin** → TIDAK punya halaman Laporan

### 9.2 Tab Utama

```
[Harian] [Bulanan] [Tahunan]
```

### 9.3 Tab Harian

**Statistik:**
- Total transaksi (jumlah + nominal)
- Perbandingan kemarin: ↑/↓ Rp X (warna hijau/merah)
- Breakdown: Obat vs Praktek

**Grafik:**
- Penjualan per jam (bar chart 06:00–21:00)

**Daftar:**
- Top 10 Obat Terjual (rank, nama, jumlah, nominal)

**Operasional:**
- Obat masuk: X item, nominal
- Obat keluar: X item
- Pasien hadir: X orang

**Action:**
- Export CSV
- Cetak Thermal (hitam putih)

### 9.4 Tab Bulanan

**Statistik:**
- Total penjualan + rata-rata/hari
- Perbandingan bulan lalu: ↑/↓ Rp X

**Grafik:**
- Tren harian sepanjang bulan

**Daftar:**
- Top 10 Obat Terjual
- Breakdown Obat vs Praktek (%)

**Operasional:**
- Total obat masuk & keluar bulan ini
- Pasien hadir: X orang

### 9.5 Tab Tahunan

**Statistik:**
- Total penjualan tahun ini

**Grafik:**
- Tren bulanan (12 bulan)

**Daftar:**
- Top 10 Obat Terjual sepanjang tahun

**Ringkasan Stok:**
- Total item di DB
- Obat habis: X
- Obat menipis: X

### 9.6 Format

- Nominal: `Rp 1.250.000`
- Tanggal: `DD Month YYYY` (Indonesia)

---

## 10. Reorganisasi Manajemen Stok

### 10.1 Halaman Obat → Tab Strip

Halaman `Obat` diubah jadi tab strip di bawah app bar:

```
[Obat] [Obat Masuk] [Obat Keluar] [Keterangan Stok] [Sinkronisasi]
```

1. **Obat** — daftar kartu obat + filter chips (Habis/Menipis/Aman/Semua, eta 1/2/3)
2. **Obat Masuk** — riwayat + form input restock
3. **Obat Keluar** — riwayat + form pengeluaran non-jual (rusak, expired, hilang)
4. **Keterangan Stok** — rename dari "Stok Alert", menampilkan obat habis & menipis
5. **Sinkronisasi** — koreksi/audit stok fisik

### 10.2 Tab "Obat Keluar"

- Flow berbeda dari Transaksi (Transaksi = penjualan)
- Obat Keluar = expenditure non-jual
- Semua etalase (termasuk etalase 3, untuk Owner)

### 10.3 Route Change

- `/stok-alert` route di-remove
- Stok Alert hanya accessible lewat tab "Keterangan Stok"

---

## 11. Pasien Non-Praktek — Tidak Dicatat

- Pasien hanya beli obat (non-praktek) → **tidak** dicatat datanya
- Tidak masuk ke tabel `pasien`, `kehadiran_pasien`, `kunjungan_pasien`
- Cukup transaksi saja (id_pasien = null)
- Sudah perilaku default sistem

---

## 12. File yang Berubah ( likelihood tinggi)

```
Navigasi & Routing:
  lib/core/routing/app_router.dart          — hapus /stok-alert route
  lib/core/routing/app_route_registry.dart   — update registry

Dashboard:
  lib/pages/dashboard_page.dart             — redesign jadi home base + shortcut cards

Bottom Navigation:
  lib/widgets/ (bottom_nav widget)          — ubah dari 5 tab jadi 3 tab

Menu Utama:
  lib/pages/login_page.dart                  — update desain sesuai screenshot + logo SinShe
  lib/pages/obat_page.dart                  — tambah TabBar 5 tab
  lib/pages/stok_alert_page.dart            — merge ke dalam obat_page.dart

Transaksi:
  lib/pages/transaksi_form_page.dart        — ubah flow + filter etalase
  lib/pages/transaksi_hub_page.dart         — update
  lib/pages/preview_cetak_page.dart         — ubah struk ke hitam putih

Riwayat Transaksi:
  lib/pages/riwayat_transaksi_page.dart      — TAB BARU (1: transaksi, 2: restock+keluar)
  lib/pages/akun_page.dart                  — dark mode, logout, profile

Laporan:
  lib/features/laporan/                     — overhaul: harian/bulanan/tahunan + top 10
  lib/pages/laporan_page.dart               — Owner only (cek role)

Print Service:
  lib/core/services/receipt_printer_service.dart — ubah struk ke hitam putih

Assets:
  assets/logo/logo_sinshe_versi_png.png     — copy dari mockup/screenshot/
  assets/logo/logo_sinshe_login.jpeg

Konfigurasi Android:
  pubspec.yaml                             — app name → "SinShe Jaya Abadi"
  android/app/build.gradle                  — app name
  android/app/src/main/AndroidManifest.xml  — app label
  android/app/src/main/res/values/strings.xml
  android/app/src/main/res/mipmap-*/ic_launcher.png — app icon

Database:
  (opsional) tabel print_queue             — CREATE TABLE print_queue (...)
```

---

## 13. Emil Design — Motion & Polish

### 13.1 Approach

**Opsi C** — Buat design token + apply ke halaman baru.

- Scope: **halaman baru yang dibuat / diedit besar**
- Pages existing tidak perlu refactor
- Pages yang diedit kecil-kecilan (fix bug, tweak spacing) juga tidak perlu

### 13.2 Token Location

File: `lib/core/design_system/emil_design.dart`

Export semua duration, curve, dan scale values yang konsisten di seluruh app.

### 13.3 Token Values

```dart
class EmilDesign {
  // ── Durations ──
  static const fast      = Duration(milliseconds: 150);
  static const normal    = Duration(milliseconds: 300);
  static const slow      = Duration(milliseconds: 500);

  // ── Curves ──
  static const enter     = Curves.easeOutCubic;
  static const exit     = Curves.easeInCubic;
  static const gesture  = Curves.easeOutCubic; // swipe/drag release
  static const toggle    = Curves.easeInOutCubic;

  // ── Scale ──
  static const pressScale  = 0.97;   // button/icon tap
  static const hoverScale = 1.04;   // card hover (web/desktop)

  // ── Spring (if needed for drag) ──
  // static final spring = SpringDescription(
  //   mass: 1.0,
  //   stiffness: 400,
  //   damping: 24,
  // );
}
```

### 13.4 Usage

```dart
// Widget animate in
AnimatedOpacity(
  opacity: isVisible ? 1.0 : 0.0,
  duration: EmilDesign.normal,
  curve: EmilDesign.enter,
  child: MyContent(),
)

// Button press
GestureDetector(
  onTapDown: (_) => setState(() => pressed = true),
  onTapUp:   (_) => setState(() => pressed = false),
  child: AnimatedScale(
    scale: pressed ? EmilDesign.pressScale : 1.0,
    duration: EmilDesign.fast,
    child: MyButton(),
  ),
)

// Page transition
PageRouteBuilder(
  transitionDuration: EmilDesign.normal,
  pageBuilder: (_, __, ___) => NewPage(),
  transitionsBuilder: (_, animation, __, child) {
    return FadeTransition(opacity: animation, child: child);
  },
)
```

### 13.5 What TO Animate

- Widget masuk/keluar halaman (fade + slide)
- Card/modal muncul (scale + fade)
- Snackbar/toast (slide dari bawah)
- Pull-to-refresh indicator
- Tab content switch

### 13.6 What NOT TO Animate

- Keyboard-initiated actions (keyboard muncul → jangan animasi)
- Hardware back button press → page pop, tidak animate
- Scroll physics (default Flutter scroll sudah smooth)
- Loading spinner (putar saja)

### 13.7 Reduced Motion

Di-handle saat implementasi halaman baru, menggunakan `MediaQuery.of(context).disableAnimations` — kurangi duration ke 0 untuk user yang mengaktifkan preferensi ini.

---

## 14. Keputusan Diskusi 2026-05-29 Lanjutan

### 14.1 Struk Thermal — Satu Desain Hitam Putih

- **Keputusan: Satu desain hitam putih** — preview dan hasil cetak fisik sama
- Tidak perlu dua versi (warna biru + BW)
- File yang diubah: `receipt_printer_service.dart` (sudah ada) + `receipt_printer_service_bw.dart` (duplicate, dihapus atau merge)
- Preview halaman `.dart` → gunakan widget hitam putih yang sama

### 14.2 Logo SinShe — Keputusan Placeholder

- Logo SinShe **belum siap** sebagai placeholder untuk preview/mockup
- Timelines:
  - Fase 1 (mendesain UI): gunakan **placeholder** (text "SIN SHE JAYA ABADI" di header)
  - Fase 2 (logo siap): replace placeholder dengan asset logo `.png/.jpeg`
- Workflow: design dulu, baru tempel logo

---

## 15. Ringkasan Perubahan Final

| No | Perubahan | Status |
|----|-----------|--------|
| 1 | Bottom nav: `[Dashboard] [Riwayat Transaksi] [Akun]` | ✅ |
| 2 | Dashboard: home base + shortcut cards ke semua fitur | ✅ |
| 3 | Hapus menu Akuntansi seluruhnya | ✅ |
| 4 | Transaksi: dipindah ke Dashboard | ✅ |
| 5 | Riwayat Transaksi: Tab 1 (transaksi), Tab 2 (restock+obat keluar) | ✅ |
| 6 | Print Queue: tabel `print_queue` di DB | ✅ |
| 7 | Owner input Praktek → Notifikasi ke Admin → Admin cetak | ✅ |
| 8 | Admin input non-praktek → Admin cetak sendiri | ✅ |
| 9 | Owner bisa cetak sendiri (rare case) | ✅ |
| 10 | Transaksi Obat → eta 1&2, Transaksi Praktek → eta 3 | ✅ |
| 11 | Login: desain dari `login_app.jpeg` + logo SinShe | ✅ |
| 12 | Logo SinShe: login, APK icon, splash screen | ✅ |
| 13 | Struk: satu desain, hitam putih (preview + cetak) | ✅ |
| 14 | Rename: "Klinik" → "SinShe Jaya Abadi" (user-facing) | ✅ |
| 15 | App name: "SinShe Jaya Abadi" | ✅ |
| 16 | Laporan Owner: Harian/Bulanan/Tahunan komprehensif, Top 10 | ✅ |
| 17 | Admin: tidak punya halaman Laporan | ✅ |
| 18 | Etalase 3: hanya Owner akses | ✅ |
| 19 | Etalase 3: tampil sebagai kartu obat individual | ✅ |
| 20 | Pasien non-praktek: tidak dicatat datanya | ✅ |
| 21 | Manajemen Stok: tab Obat Masuk/Keluar/Keterangan Stok/Sinkronisasi | ✅ |
| 22 | Rename "Stok Alert" → "Keterangan Stok Obat" | ✅ |
