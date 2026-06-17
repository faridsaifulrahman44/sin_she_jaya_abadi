# F2 — Feature Maturity Upgrade
## Klinik Sin She Jaya Abadi
**Tanggal:** 2026-05-18
**Author:** Claude Opus 4.6 (Brainstorming with Owner)
**Status:** Approved

---

## RINGKASAN EKSEKUTIF

Enam fitur baru yang membangun aplikasi klinik dari "operasional dasar" menjadi "sistem manajemen klinik terpadu". Enam fitur: Stok Alert, konsistensi UI Material Symbols, laporan multi-format, timeline pasien, jadwal reminder, dan mini akuntansi.

**Order of Implementation:**
1. Phase 1 — Infrastruktur: F2-F (Material Symbols) + F2-E (Schema)
2. Phase 2 — F2-C: Stok Alert System
3. Phase 3 — F2-D: Jadwal Praktik + Pasien Kontrol
4. Phase 4 — F2-B: Patient Timeline
5. Phase 5 — F2-A: Laporan Export
6. Phase 6 — F2-E: Laporan Akuntansi

---

## FEATURE C — Stok Alert System (Priority #1)

### Konsep
Sistem peringatan otomatis untuk obat yang stoknya menipis atau habis. Alert tampil sebagai badge di menu Obat, plus halaman daftar alert khusus. Untuk arsip店长, tersedia opsi cetak thermal laporan stok kapan saja.

### Logika Ambang Batas
Dua level alert per obat:

| Level | Kondisi | Warna Badge |
|---|---|---|
| **Habis** | `stok_sistem == 0` | Merah |
| **Menipis** | `1 <= stok_sistem <= batas_minimum` | Orange |

`batas_minimum` per-obat: ambil dari kolom `stok_minimum` di tabel `obat` (jika null, default `5`).

### UI: In-App Badge
- **Di dashboard:** Card "Data Obat" menampilkan jumlah obat alert (badge merah/orange).
- **Di halaman `ObatPage`:** Tab chip tambahan: `[Semua] [Aman] [Menipis] [Habis]`. Default: `Semua`.
- **Di halaman `ObatDetail`:** Tampilkan status alert + tanggal terakhir restock.

### UI: Halaman Alert Stok
Route baru: `/stok-alert`
- Header: jumlah total alert (habis + menipis).
- List grouped: bagian "Habis" di atas, "Menipis" di bawah.
- Setiap item: nama obat, etalase, stok saat ini, batas minimum.
- Tombol **"Cetak Thermal"** → thermal print via Bluetooth printer.
- Owner only — role check wajib.

### Cetak Thermal
Format struk 58mm: header klinik + daftar obat alert grouped by level (Habis/Menipis) + footer timestamp.

---

## FEATURE F — UI Material Symbols + Polish (Priority #2)

### Konsep
Migrate seluruh icon dari HugeIcons ke Material Symbols (Rounded style). Buat wrapper `AppSymbols` baru. Audit halaman besar untuk konsistensi spacing/font tokens.

### Arsitektur Icon
Wrapper baru `lib/core/ui/app_symbols.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_rounded.dart';

class AppSymbols {
  static const IconData wallet   = MaterialSymbols.wallet_rounded;
  static const IconData pills   = MaterialSymbols.medication_rounded;
  static const IconData qris    = MaterialSymbols.qr_code_rounded;
  static const IconData tunai   = MaterialSymbols.payments_rounded;
  // ... semua icon lain
}
```
- Style: `MaterialSymbolsRounded` (soft, medical-grade).
- Weight default: `SymbolWeight.w400`.
- Tidak perlu `HugeIcon` wrapper — pakai `Icon(AppSymbols.xxx)` langsung.
- `app_icons.dart` tetap ada (deprecated) — tidak dihapus untuk backward compatibility.

### Package Changes
**Tambah di `pubspec.yaml`:**
```yaml
material_symbols_icons: ^4.3000.0
```

**Hapus dari `pubspec.yaml`:**
```yaml
hugeicons: ^1.1.6
```

### HugeIcons Cleanup Checklist
- [ ] `grep -r "HugeIcon\|hugeicons" lib/` → semua harus zero results
- [ ] `grep -r "import.*hugeicons" lib/` → semua harus zero results
- [ ] `grep -r "AppIcons" lib/` → semua sudah menggunakan `AppSymbols`
- [ ] Hapus `hugeicons` dari `pubspec.yaml`
- [ ] `flutter pub get` → verify no conflicts
- [ ] Run all tests → must pass

### Audit Halaman Besar
File yang perlu di-audit untuk konsistensi spacing/font:
- `transaksi_form_page.dart` (1.480 baris) — Swap icon + spacing consistency
- `transaksi_hub_page.dart` (1.206 baris) — Swap icon + spacing consistency
- `dashboard_page.dart` (991 baris) — Swap icon
- `obat_page.dart`, `laporan_page.dart`, dst. — Swap icon

Tidak mengubah layout — hanya konsistensi spacing/font tokens.

---

## FEATURE A — Laporan + Export (Priority #3)

### Konsep
Export laporan multi-format untuk Owner. Tiga format: Thermal (ringkasan harian), PDF/A4 (laporan bulanan), CSV (data mentah). Semua extend halaman `LaporanPage` existing.

### Format 1: Thermal — Ringkasan Harian
Tab baru "Harian" di `LaporanPage` + tombol **"Cetak Thermal"**.
Output: struk 58mm ringkasan transaksi hari itu. Isi: omzet total, jumlah transaksi, breakdown Obat vs Praktek, breakdown pembayaran Tunai vs QRIS.

### Format 2: PDF/A4 — Laporan Bulanan
Tab baru "Bulanan" di `LaporanPage` + date picker bulan + tombol **"Export PDF"**.
Isi: header klinik + periode, tabel ringkasan harian, summary bulanan, top 5 obat terjual, simple bar chart (via `fl_chart`).
Library: `pdf` + `printing`.

### Format 3: CSV — Data Mentah
Tombol **"Export CSV"** di tab Harian/Bulanan. Kolom: tanggal, jenis, metode_bayar, total, item_count, admin.
Library: `csv`.

### Package Baru
```yaml
pdf: ^3.11.0
printing: ^5.13.0
csv: ^6.0.0
```

### Akses Kontrol
- Semua fitur export: **Owner only** (`role.isOwner`).
- Jika bukan owner → tombol/tombol tidak dirender.

---

## FEATURE B — Patient Timeline (Priority #4)

### Konsep
Tab baru di `PasienDetailPage` ("Timeline") yang menampilkan kronologis aktivitas pasien dalam satu view terpadu.

### Route
Extend `PasienDetailPage`: tab ke-3 (setelah "Info" dan "Riwayat Transaksi").
Path tetap `/pasien-detail/:id`.

### Data Sources
| Sumber | Tabel/Repo | Notes |
|---|---|---|
| Transaksi Obat | `transaksi`, `transaksi_item` | Filter `id_pasien`, tampilkan obat + qty |
| Transaksi Praktek | `transaksi` | Tampilkan durasi, catatan |
| Kehadiran | `kehadiran_pasien` | Status hadir/tidak |
| Kunjungan | `kunjungan_pasien` | Keluhan, hasil |
| Catatan Hasil | `catatan_hasil` | Dokumen hasil pemeriksaan |

### UI: Timeline Item Types
Ikon berbeda per jenis (AppSymbols):

| Jenis | Icon | Warna |
|---|---|---|
| Transaksi Obat | `medication_rounded` | Green |
| Transaksi Praktek | `medical_services_rounded` | Blue |
| Kehadiran Hadir | `check_circle_rounded` | Teal |
| Kehadiran Tidak Hadir | `cancel_rounded` | Red |
| Kunjungan | `clinical_notes_rounded` | Indigo |
| Catatan Hasil | `description_rounded` | Orange |

### Layout Halaman
```
Tab Timeline
├── Header Statistik
│   ├── Total Transaksi: 24
│   ├── Total Biaya: Rp 2.350.000 (owner only — "-" untuk admin)
│   └── Kunjungan Terakhir: 12 Mei 2026
├── Filter Bar: [Semua] [Date Range] [Jenis ▼]
└── Timeline List (grouped by bulan)
    └── Item per aktivitas dengan icon + warna + detail
[+] Tombol Tambah Catatan (quick note)
```

### Quick Note
Modal bottom sheet: text field max 200 karakter + label [Nota/Keluhan/Catatan]. Langsung save ke `catatan_hasil` tanpa form panjang.

### Statistik: Role Check
| Info | Owner | Admin |
|---|---|---|
| Total transaksi (count) | ✅ | ✅ |
| Total biaya (Rp) | ✅ | ❌ tampilkan "-" |
| Frekuensi terakhir | ✅ | ✅ |

---

## FEATURE D — Jadwal + Reminder (Priority #5)

### Konsep
Dua subsistem: (1) Jadwal Praktik klinik (Owner only), (2) Jadwal Kontrol Pasien rutin (Owner + Admin). Badge reminder di kalender dan halaman detail pasien.

### D1: Jadwal Praktik Klinik

**Model:** `lib/data/models/jadwal_praktik_model.dart`
```dart
class JadwalPraktikModel {
  int? id;
  int hari;         // 1=Senin .. 7=Minggu
  String jamBuka;    // "08:00"
  String jamTutup;   // "17:00"
  bool aktif;
  DateTime? updatedAt;
}
```

**Halaman baru:** `/jadwal-praktik` — Owner only.
- List 7 hari (Senin-Minggu).
- Toggle aktif/inaktif + time picker jam buka/tutup.
- Tombol "Simpan".
- Default: senin-jumat 08:00-17:00, sabtu 08:00-12:00, minggu libur.

**Dashboard integration:** Jika hari ini bukan hari operasional → banner "Klinik Tutup Hari Ini" di header.

### D2: Jadwal Kontrol Pasien

**Model:** `lib/data/models/jadwal_kontrol_pasien_model.dart`
```dart
class JadwalKontrolPasienModel {
  int? id;
  int idPasien;
  int intervalHari;      // misal: 7
  DateTime? tanggalMulai;
  DateTime? tanggalAkhir; // nullable
  String? catatan;
  DateTime createdAt;
}
```

**Halaman:** Tab baru di `PasienDetailPage` — "Jadwal Kontrol".
- Tampilkan jadwal kontrol berikutnya.
- Tambah/hapus/edit jadwal kontrol.
- Toggle aktif/nonaktif.

**Computed tanggal berikutnya:**
```dart
DateTime getNextKontrol(DateTime mulai, int interval) {
  DateTime next = mulai;
  final now = DateTime.now();
  while (next.isBefore(now)) {
    next = next.add(Duration(days: interval));
  }
  return next;
}
```

### D3: Calendar View Extension
Extend `KehadiranTabContent` (kalender 12-bulan yang sudah ada):
- Hari operasional: warna teal. Hari libur: abu-abu.
- Dot indicator di tanggal yang ada jadwal kontrol.
- Badge "X pasien kontrol" untuk tanggal hari ini.
- Badge "X belum kontrol" untuk tanggal terlewat.

### D4: Reminder di PasienDetail
Di tab Info `PasienDetailPage`:
```
Kontrol berikutnya: 25 Mei 2026 (7 hari lagi) ← hijau
Kontrol berikutnya: 15 Mei 2026 (3 hari lalu) ← oranye (terlewat)
Kontrol berikutnya: Tidak terjadwal          ← abu-abu
```

### Repository
- `lib/data/repositories/jadwal_praktik_repository.dart`
- `lib/data/repositories/jadwal_kontrol_repository.dart`

---

## FEATURE E — Mini Akuntansi (Priority #6)

### Konsep
Modul kas masuk/keluar otomatis + manual. Rugi-laba ringkasan bulanan. Semua owner only. Dua perubahan schema (dijelaskan di bawah).

### E1: Schema Perubahan (SQL Final)

**A. Tambah kolom `status_lunas` ke `transaksi`:**
```sql
ALTER TABLE public.transaksi
ADD COLUMN IF NOT EXISTS status_lunas
  TEXT NOT NULL DEFAULT 'lunas'
  CHECK (status_lunas IN ('lunas', 'belum_lunas'));

COMMENT ON COLUMN public.transaksi.status_lunas
  IS 'lunas | belum_lunas. Default lunas (semua data lama langsung lunas)';
```

**B. Tabel baru `kas_keluar`:**
```sql
CREATE TABLE IF NOT EXISTS public.kas_keluar (
  id           SERIAL PRIMARY KEY,
  tanggal      DATE NOT NULL DEFAULT CURRENT_DATE,
  kategori     TEXT NOT NULL,
  jumlah       NUMERIC(12,0) NOT NULL CHECK (jumlah > 0),
  keterangan   TEXT,
  id_admin     INTEGER REFERENCES public.admin(id_admin),
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.kas_keluar
  IS 'Pengeluaran operasional klinik. Owner only.';

ALTER TABLE public.kas_keluar ENABLE ROW LEVEL SECURITY;

CREATE POLICY "kas_keluar_owner_only"
  ON public.kas_keluar
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin a
      WHERE a.id_admin = auth.uid()::integer
        AND a.role = 'owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin a
      WHERE a.id_admin = auth.uid()::integer
        AND a.role = 'owner'
    )
  );
```

**Kategori predefined:** Pembelian Obat/Bahan, Listrik & Air, Gaji Staff, Transportasi, Lainnya.

### E2: Data Sources

| Komponen | Source |
|---|---|
| Kas Masuk Obat | `transaksi WHERE jenis_transaksi = 'obatReadyStock' AND status_lunas = 'lunas'` |
| Kas Masuk Praktek | `transaksi WHERE jenis_transaksi = 'praktekCustom' AND status_lunas = 'lunas'` |
| Kas Keluar | `kas_keluar` |
| Piutang | `transaksi WHERE status_lunas = 'belum_lunas'` |

### E3: Halaman Laporan Akuntansi

Route baru: `/laporan-akuntansi` — **Owner only** (terpisah dari `LaporanPage`).

**Tab 1: Kas Masuk**
- List transaksi harian grouped by tanggal.
- Filter date range.
- Summary: total hari ini / minggu ini / bulan ini.

**Tab 2: Kas Keluar**
- List dari `kas_keluar` grouped by tanggal.
- Tombol "Tambah Pengeluaran": modal (kategori dropdown + jumlah + keterangan).
- Filter date range + kategori.

**Tab 3: Rugi-Laba**
- Bulan picker.
- Statement: Pendapatan breakdown → Pengeluaran breakdown → Laba Bersih.
- Simple dual-bar chart (via `fl_chart`).

**Tab 4: Piutang**
- List `status_lunas = 'belum_lunas'`.
- Per item: nama pasien, tanggal, jumlah, tombol "Tandai Lunas".
- Total piutang di header.

### Model & Repository
- `lib/data/models/kas_keluar_model.dart`
- `lib/data/repositories/kas_keluar_repository.dart`

---

## PACKAGE DEPENDENCIES (F2 Total)

```yaml
# Tambahan untuk F2
dependencies:
  material_symbols_icons: ^4.3000.0
  pdf: ^3.11.0
  printing: ^5.13.0
  csv: ^6.0.0

# Dihapus dari F2
hugeicons: ^1.1.6  # dihapus setelah migration selesai
```

---

## ROUTES BARU (F2)

| Route | Page | Akses |
|---|---|---|
| `/stok-alert` | `StokAlertPage` | Owner |
| `/jadwal-praktik` | `JadwalPraktikPage` | Owner |
| `/laporan-akuntansi` | `LaporanAkuntansiPage` | Owner |
| `/pasien-detail/:id` | extend | + Tab Timeline + Tab Jadwal Kontrol |

---

## MODEL BARU (F2 Total)

- `lib/data/models/jadwal_praktik_model.dart`
- `lib/data/models/jadwal_kontrol_pasien_model.dart`
- `lib/data/models/kas_keluar_model.dart`

---

## ORDER OF IMPLEMENTATION

```
Phase 1 — Infrastruktur
├── F2-F: Material Symbols wrapper + HugeIcons removal
└── F2-E: Schema kas_keluar + status_lunas

Phase 2 — Stok Alert
└── F2-C: Stok Alert System

Phase 3 — Jadwal
└── F2-D: Jadwal Praktik + Pasien Kontrol + Calendar extend

Phase 4 — Patient Timeline
└── F2-B: Patient Timeline

Phase 5 — Laporan
└── F2-A: Laporan Export (thermal + PDF + CSV)

Phase 6 — Accounting
└── F2-E: Laporan Akuntansi (depends on Phase 1 schema)
```

---

## PRINSIP IMPLEMENTASI

1. **Owner only gate** — semua fitur baru yang menampilkan nominal/uang wajib di-wrap `role.isOwner`.
2. **No schema change tanpa persetujuan** — SQL finale ditampilkan dulu, tunggu "LANJUT" sebelum eksekusi.
3. **Material Symbols everywhere** — semua icon baru F2 pakai `AppSymbols`.
4. **Tidak ubah tabel transaksi existing** — kecuali kolom baru `status_lunas` (approach A).
5. **HugeIcons safety net** — `app_icons.dart` tidak dihapus sampai semua consumer sudah dimigrate.

---

*Spec ini di-generate via brainstorming skill dan disetujui owner pada 2026-05-18. Perubahan dari spec harus di-review ulang.*