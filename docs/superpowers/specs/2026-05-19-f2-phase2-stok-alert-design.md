# F2-C: Stok Alert System — Design Spec
## Phase 2 Feature Maturity — Klinik Sin She Jaya Abadi

---

## 1. Overview & Goals

Memberikan visual alert stok menipis/habis ke owner agar bisa reorder obat sebelum kehabisan.
Fokus ke **in-app indicator** + **cetak thermal laporan alert**. Bukan push notification.

**Success criteria:**
- Owner bisa lihat badge stok kritis dari dashboard
- Owner bisa filter ObatPage berdasarkan level stok
- Owner bisa buka halaman `/stok-alert` untuk laporan stok kritis
- Owner bisa cetak thermal laporan stok alert

---

## 2. Data Model

### StokAlertCategory (enum)

```dart
enum StokAlertCategory { habis, menipis, aman }
```

### StokAlertItem (DTO)

```dart
class StokAlertItem {
  final int idObat;
  final String namaObat;
  final String? fotoKey;
  final int stokSaatIni;
  final int stokMinimum;
  final StokAlertCategory kategori;
}
```

### StokAlertSummary (DTO)

```dart
class StokAlertSummary {
  final List<StokAlertItem> habis;
  final List<StokAlertItem> menipis;
  final List<StokAlertItem> aman;

  int get totalHabis => habis.length;
  int get totalMenipis => menipis.length;
  bool get hasHabis => totalHabis > 0;
  bool get hasMenipis => totalMenipis > 0;
}
```

---

## 3. Architecture

### Alert Logic — Pure Function (no service, no repository)

File: `lib/features/stok/stok_alert_logic.dart`

```dart
StokAlertCategory categorizeObat(ObatModel obat, {int defaultMinimum = 5});

StokAlertSummary buildStokAlertSummary(List<ObatModel> obatList);

List<ObatModel> filterByStokAlertCategory(
  List<ObatModel> obatList,
  StokAlertCategory category,
);
```

### Threshold Logic

| Kategori | Kondisi | Badge Color |
|----------|---------|-------------|
| `habis` | `stok_saat_ini == 0` | Merah (`cdanger`) |
| `menipis` | `1 <= stok_saat_ini <= stok_minimum` | Orange (`cwarning`) |
| `aman` | `stok_saat_ini > stok_minimum` | Tidak ada badge |

- `stok_minimum` per-obat dari kolom DB → jika null, fallback ke default `5`
- Tidak mengubah kolom `stok_minimum` yang sudah ada di DB

---

## 4. UI Components

### 4a. Badge di Dashboard Card Obat

Lokasi: `lib/pages/dashboard_page.dart` — card menu "Obat" (bagian bawah, dekat card lain)

**Logic tampilan badge:**
- Jika `summary.hasHabis` → tampilkan badge merah "X habis"
- Else if `summary.hasMenipis` → tampilkan badge orange "X menipis"
- Else → tidak ada badge

**Visual:**
- Badge: container bulat, background `cdanger` (merah) atau `cwarning` (orange)
- Text: putih, font bold, 11sp
- Posisi: pojok kanan atas card, di luar shadow card
- Dipasang di `ModernDashboardCard` atau di wrapper card Obat

### 4b. Filter Chip di ObatPage

Lokasi: `lib/pages/obat_page.dart` — atas list obat, menggantikan atau melengkapi chip etalase

**Chip order:** `[Habis] [Menipis] [Aman] [Semua]`
- Default selected: `Semua` (tidak ada filter, tampilkan semua)
- `[Habis]` chip: background `cdanger` soft (`cdanger.withOpacity(0.1)`), text `cdanger`
- `[Menipis]` chip: background `cwarning` soft, text `cwarning`
- `[Aman]` chip: neutral (surface bg, text secondary)
- `[Semua]` chip: neutral
- Urutan ini menaruh alert paling urgent di kiri (tidak perlu scroll)

**Behavior:**
- Tap chip → filter list obat sesuai kategori
- List obat tetap pakai data yang sudah di-fetch saat halaman load
- Sinkron dengan badge dashboard (keduanya baca `ObatModel` yang sama)

### 4c. Halaman /stok-alert (Owner Only)

Route: `/stok-alert`
Akses: Owner only (gate via `AdminSession.isOwner()`)

**Layout:**
1. AppBar: "Stok Alert" + jam/tanggal real-time (mirip dashboard owner)
2. Summary card: 3 kolom [Habis: X] [Menipis: X] [Aman: X] — warna per kategori
3. Section "Obat Habis" (jika ada): list `ObatAlertCard` — nama, stok, etalase
4. Section "Obat Menipis" (jika ada): list `ObatAlertCard` — nama, stok, stok_minimum
5. Tombol "Cetak Laporan" di bawah

**ObatAlertCard:**
- Icon alert (merah/orange sesuai kategori)
- Nama obat + etalase
- "Stok: X | Min: Y"
- Jika `stok_minimum` null, tampilkan "Min: 5 (default)"

### 4d. Cetak Thermal Laporan Stok Alert

Trigger: tombol "Cetak Laporan" di halaman `/stok-alert`

Menggunakan `ReceiptPrinterService` yang sudah ada di `lib/core/services/receipt_printer_service.dart`.
Paper size: 58mm thermal printer.

**Format thermal:**
```
=== STOK ALERT ===
Klinik Sin She Jaya Abadi
19/05/2026 14.30

⚠️ HABIS (2):
- Die Da Tay Ping Yao Jing
- Sanjin Tablets
  Stok: 0 | Min: 5

⚠️ MENIPIS (3):
- Xin Yi Qiao Pian
  Stok: 2 | Min: 5
- ...

--------------------
Generated: 19/05/2026 14.30
```

---

## 5. Routing

Tambah route di `AppRouteRegistry`:

```dart
static const String stokAlert = '/stok-alert';
```

Akses menu: dari dashboard owner, card "Obat" badge trigger → navigasi ke `/stok-alert`. Atau bisa ditambah sebagai menu item di navigation drawer owner.

---

## 6. Owner-Only Gate

Semua komponen Stok Alert (badge dashboard, filter ObatPage, halaman `/stok-alert`, cetak thermal) hanya accessible untuk **role owner**.

- Badge di dashboard: hanya render untuk owner (cek `AdminSession.isOwner()`)
- Filter chip ObatPage: tampil untuk semua role, karena owner saja yang perlu baca badge
- Halaman `/stok-alert`: redirect non-owner ke dashboard
- Cetak thermal: hanya owner bisa trigger

**Note:** Filter chip di ObatPage tetap tampil untuk admin — owner butuh admin bisa lihat daftar obat dan filter. Hanya badge dan halaman detail yang owner-only.

---

## 7. File Map

### New Files

| File | Deskripsi |
|------|-----------|
| `lib/features/stok/stok_alert_logic.dart` | Pure functions: categorizeObat, buildStokAlertSummary, filterByStokAlertCategory |
| `lib/data/models/stok_alert_item.dart` | DTO StokAlertItem + StokAlertSummary |
| `lib/pages/stok_alert_page.dart` | Halaman /stok-alert (owner only) + private widget di file yang sama |
| `test/features/stok/stok_alert_logic_test.dart` | Unit test untuk threshold logic |

### Modified Files

| File | Perubahan |
|------|-----------|
| `lib/pages/dashboard_page.dart` | Tambah badge di card Obat |
| `lib/pages/obat_page.dart` | Tambah filter chip [Habis][Menipis][Aman][Semua] |
| `lib/core/routing/app_route_registry.dart` | Tambah route `/stok-alert` |
| `lib/core/services/receipt_printer_service.dart` | Tambah method buildStokAlertReceipt() |

> Note: `_StokAlertSummaryCard` dan `_ObatAlertCard` dijadikan **private widget** di dalam `stok_alert_page.dart` (tidak perlu subfolder khusus). Jika nanti dipakai di halaman lain, baru ekstrak ke `lib/widgets/stok_alert/`.

---

## 8. Dependencies

- Tidak ada dependency baru (package sudah ada)
- Pakai `ReceiptPrinterService` existing untuk cetak thermal
- Pakai `AppSymbols` untuk ikon
- Pakai `ObatModel` existing (stok_saat_ini, stok_minimum sudah ada di model)

---

## 9. Self-Review Checklist

- [x] Placeholder/TODO: tidak ada
- [x] Scope: focused, tidak ada fitur di luar stok alert
- [x] Konsisten: threshold logic satu tempat (stok_alert_logic.dart)
- [x] Owner-only gate: semua komponen alert gate dengan isOwner()
- [x] Tidak ubah kolom DB `stok_minimum`
- [x] Follow pola kode existing (ReceiptPrinterService, ModernDashboardCard, dll.)
