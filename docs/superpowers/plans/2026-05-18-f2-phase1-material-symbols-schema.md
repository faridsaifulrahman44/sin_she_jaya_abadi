# Phase 1: Material Symbols + Schema Infrastructure
## F2 Feature Maturity — Klinik Sin She Jaya Abadi

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace HugeIcons with Material Symbols across the entire codebase, add two schema changes (status_lunas + kas_keluar), and set the foundation for all subsequent F2 features.

**Architecture:**
- `lib/core/ui/app_symbols.dart` — new wrapper class for Material Symbols (Rounded style), mirrors AppIcons structure
- `lib/core/ui/app_icons.dart` — deprecated in-place, NOT deleted (backward compat safety net)
- All pages refactored: `HugeIcon(icon: AppIcons.xxx)` → `Icon(AppSymbols.xxx)`
- All `import 'package:hugeicons/hugeicons.dart'` → removed
- Schema: ALTER TABLE transaksi + CREATE TABLE kas_keluar

**Tech Stack:** `material_symbols_icons: ^4.3000.0`, `pdf: ^3.11.0`, `printing: ^5.13.0`, `csv: ^6.0.0`

**Note:** SQL schema changes must be shown to user and user must type "LANJUT" before execution.

---

## FILE MAP

### New Files
- `lib/core/ui/app_symbols.dart` — Material Symbols wrapper (61 constants mapped from AppIcons)

### Modified Files
- `pubspec.yaml` — add material_symbols_icons, pdf, printing, csv; remove hugeicons
- `lib/core/ui/app_icons.dart` — deprecate via Dart doc comment
- `lib/pages/transaksi_form_page.dart:527,532` — swap HugeIcon → Icon for tunai/qris
- `lib/pages/dashboard_page.dart` — swap all HugeIcons (12 icons)
- `lib/pages/laporan_page.dart` — swap all HugeIcons (5 icons)
- `lib/pages/obat_page.dart` — swap all HugeIcons (5 icons)
- `lib/pages/obat_form_page.dart` — swap HugeIcon
- `lib/pages/obat_detail_page.dart` — swap HugeIcons (3 icons)
- `lib/pages/obat_hub_page.dart` — swap HugeIcon
- `lib/pages/obat_masuk_page.dart` — swap HugeIcons (2 icons)
- `lib/pages/obat_masuk_detail_page.dart` — swap HugeIcons (4 icons)
- `lib/pages/obat_masuk_tanggal_form_page.dart` — swap HugeIcon
- `lib/pages/obat_keluar_page.dart` — swap HugeIcons (2 icons)
- `lib/pages/obat_keluar_detail_page.dart` — swap HugeIcons (4 icons)
- `lib/pages/obat_keluar_form_page.dart` — swap HugeIcons (2 icons)
- `lib/pages/obat_keluar_item_row.dart` — swap HugeIcon
- `lib/pages/obat_keluar_tanggal_form_page.dart` — swap HugeIcon
- `lib/pages/pasien_detail_page.dart` — swap HugeIcons (6 icons)
- `lib/pages/pasien_form_page.dart` — swap HugeIcon
- `lib/pages/kehadiran_tab_content.dart` — swap HugeIcons (7 icons)
- `lib/pages/kehadiran_detail_page.dart` — swap HugeIcons (4 icons)
- `lib/pages/kehadiran_form_page.dart` — swap HugeIcon
- `lib/pages/kunjungan_form_page.dart` — swap HugeIcon
- `lib/pages/sinkronisasi_stok_page.dart` — swap HugeIcons (2 icons)
- `lib/pages/sinkronisasi_stok_form_page.dart` — swap HugeIcon
- `lib/pages/sinkronisasi_stok_panels.dart` — swap HugeIcons (3 icons)
- `lib/pages/forgot_password_page.dart` — swap HugeIcons (4 icons)
- `lib/pages/reset_password_page.dart` — swap HugeIcon
- `lib/pages/login_page.dart` — swap HugeIcon
- `lib/pages/login_layouts.dart` — swap HugeIcons (5 icons)
- `lib/widgets/app_error_view.dart` — swap HugeIcons (2 icons)
- `lib/widgets/app_empty_view.dart` — swap HugeIcon

### Test Files (update to reflect new imports)
- `test/core/date_range_validator_test.dart` — no change
- `test/core/formatters_test.dart` — no change
- `test/core/parsers_test.dart` — no change
- `test/core/error/app_error_mapper_test.dart` — no change
- `test/core/services/receipt_printer_service_test.dart` — no change
- All other test files — no change (tests use mock data, no icons)

---

## TASK 1: Create AppSymbols Wrapper

**Files:**
- Create: `lib/core/ui/app_symbols.dart`

**Audit basis:** 61 static constants mapped from `AppIcons`. Every HugeIcon name converted to equivalent `MaterialSymbolsRounded`.

- [ ] **Step 1: Create app_symbols.dart with full icon mapping**

```dart
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_rounded.dart';

/// Material Symbols wrapper — rounded style.
/// Ganti semua HugeIcons/AppIcons dengan Icon(AppSymbols.xxx).
///
/// Style: Rounded — soft, medical-grade look.
/// Weight: SymbolWeight.w400 (default untuk semua).
///
/// Wrapper ini tidak menggunakan HugeIcon — langsung Icon(...)
/// karena MaterialSymbols adalah IconData native Flutter.
///
/// DEPRECATED: app_icons.dart TIDAK dihapus — tetap ada untuk
/// backward compatibility safety net sampai semua consumer dimigrate.
class AppSymbols {
  AppSymbols._();

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Branding klinik
  static const IconData klinik = MaterialSymbols.local_hospital_rounded;

  /// Email / username
  static const IconData mail = MaterialSymbols.mail_rounded;

  /// Password / lock
  static const IconData lock = MaterialSymbols.lock_rounded;

  /// Tampilkan password
  static const IconData eyeOn = MaterialSymbols.visibility_rounded;

  /// Sembunyikan password
  static const IconData eyeOff = MaterialSymbols.visibility_off_rounded;

  /// Tombol login
  static const IconData login = MaterialSymbols.login_rounded;

  /// Help / bantuan
  static const IconData help = MaterialSymbols.info_rounded;

  /// Send / kirim (arrow right)
  static const IconData send = MaterialSymbols.arrow_forward_rounded;

  /// Waving hand (welcome greeting)
  static const IconData wavingHand = MaterialSymbols.waving_hand_rounded;

  /// User group (people outline)
  static const IconData peopleGroup = MaterialSymbols.group_rounded;

  /// Assessment / report (analytics)
  static const IconData assessment = MaterialSymbols.analytics_rounded;

  // ─── Dashboard ────────────────────────────────────────────────────────────

  /// Toggle light theme (sun)
  static const IconData sun = MaterialSymbols.light_mode_rounded;

  /// Toggle dark theme (moon)
  static const IconData moon = MaterialSymbols.dark_mode_rounded;

  /// Logout
  static const IconData logout = MaterialSymbols.logout_rounded;

  // ─── Menu Utama ────────────────────────────────────────────────────────────

  /// Data Obat — pill/medicine
  static const IconData obat = MaterialSymbols.medication_rounded;

  /// Data Obat — pills (dedicated pill icon)
  static const IconData pills = MaterialSymbols.medication_rounded;

  /// Obat Masuk (inventory in) — package receive
  static const IconData obatMasuk = MaterialSymbols.download_rounded;

  /// Obat Keluar (inventory out) — package sent
  static const IconData obatKeluar = MaterialSymbols.upload_rounded;

  /// Data Pasien
  static const IconData pasien = MaterialSymbols.person_rounded;

  /// Pasien Hub — halaman domain pasien
  static const IconData pasienHub = MaterialSymbols.group_rounded;

  /// Daftar Hadir Pasien — clipboard
  static const IconData daftarHadir = MaterialSymbols.checklist_rounded;

  /// Laporan / analytics — chart
  static const IconData laporan = MaterialSymbols.bar_chart_rounded;

  // ─── Aksi Umum ────────────────────────────────────────────────────────────

  /// Tambah data
  static const IconData tambah = MaterialSymbols.add_rounded;

  /// Tambah (circle variant)
  static const IconData tambahCircle = MaterialSymbols.add_circle_rounded;

  /// Edit
  static const IconData edit = MaterialSymbols.edit_rounded;

  /// Edit outline (small, untuk inline actions)
  static const IconData editOutline = MaterialSymbols.edit_rounded;

  /// Hapus
  static const IconData hapus = MaterialSymbols.delete_rounded;

  /// Delete outline (small, untuk inline actions)
  static const IconData deleteOutline = MaterialSymbols.delete_rounded;

  /// Hapus sweep (bulk delete)
  static const IconData hapusSweep = MaterialSymbols.delete_forever_rounded;

  /// Remove / minus (untuk hapus item di form)
  static const IconData removeCircle = MaterialSymbols.remove_circle_rounded;

  /// Simpan — save energy
  static const IconData simpan = MaterialSymbols.save_rounded;

  /// Cari / search
  static const IconData cari = MaterialSymbols.search_rounded;

  /// Filter
  static const IconData filter = MaterialSymbols.filter_list_rounded;

  /// Sort / urutkan
  static const IconData sort = MaterialSymbols.sort_rounded;

  /// Sort A-Z
  static const IconData sortAZ = MaterialSymbols.sort_by_alpha_rounded;

  /// Refresh / reload
  static const IconData refresh = MaterialSymbols.refresh_rounded;

  /// Kembali / arrow left
  static const IconData kembali = MaterialSymbols.arrow_back_rounded;

  /// Arrow left 02
  static const IconData arrowBack = MaterialSymbols.arrow_back_rounded;

  /// Arrow right
  static const IconData arrowRight = MaterialSymbols.arrow_forward_rounded;

  /// Arrow down
  static const IconData arrowDown = MaterialSymbols.keyboard_arrow_down_rounded;

  /// Arrow up
  static const IconData arrowUp = MaterialSymbols.keyboard_arrow_up_rounded;

  /// Lihat detail / eye
  static const IconData detail = MaterialSymbols.visibility_rounded;

  /// Visibility / eye
  static const IconData visibility = MaterialSymbols.visibility_rounded;

  /// Kalender / tanggal
  static const IconData kalender = MaterialSymbols.calendar_today_rounded;

  /// Calendar today
  static const IconData calendarToday = MaterialSymbols.calendar_today_rounded;

  /// Calendar month
  static const IconData kalenderMonth = MaterialSymbols.calendar_month_rounded;

  /// Calendar 03
  static const IconData calendar03 = MaterialSymbols.calendar_today_rounded;

  /// Warning / peringatan
  static const IconData warning = MaterialSymbols.warning_rounded;

  /// Stok menipis — alert 02
  static const IconData stokMenipis = MaterialSymbols.error_rounded;

  /// Riwayat / clock
  static const IconData riwayat = MaterialSymbols.history_rounded;

  // ─── Pasien & Kehadiran ───────────────────────────────────────────────────

  /// Pasien hadir
  static const IconData pasienHadir = MaterialSymbols.check_circle_rounded;

  /// Pasien tidak hadir
  static const IconData pasienTidakHadir = MaterialSymbols.cancel_rounded;

  /// Person (generic)
  static const IconData person = MaterialSymbols.person_rounded;

  /// Event attendance — calendar check-in
  static const IconData event = MaterialSymbols.event_available_rounded;

  // ─── Laporan / Chart ──────────────────────────────────────────────────────

  /// Receipt / nota — invoice
  static const IconData receipt = MaterialSymbols.receipt_rounded;

  /// Analytics summary
  static const IconData analytics = MaterialSymbols.analytics_rounded;

  /// Chart trending up
  static const IconData trendingUp = MaterialSymbols.trending_up_rounded;

  /// Chart trending down
  static const IconData trendingDown = MaterialSymbols.trending_down_rounded;

  /// Bar chart
  static const IconData chartBar = MaterialSymbols.bar_chart_rounded;

  /// Star / terbaik
  static const IconData star = MaterialSymbols.star_rounded;

  /// Etalase / storefront
  static const IconData etalase = MaterialSymbols.storefront_rounded;

  /// Add box / unit masuk
  static const IconData addBox = MaterialSymbols.add_box_rounded;

  // ─── Obat Detail ──────────────────────────────────────────────────────────

  /// Medication / pill — health
  static const IconData medication = MaterialSymbols.medication_rounded;

  /// Input / masuk
  static const IconData input = MaterialSymbols.download_rounded;

  /// Output / keluar
  static const IconData output = MaterialSymbols.upload_rounded;

  /// Inventory
  static const IconData inventory = MaterialSymbols.inventory_2_rounded;

  // ─── UI Umum ───────────────────────────────────────────────────────────────

  /// Success / check
  static const IconData success = MaterialSymbols.check_circle_rounded;

  /// Error / gagal
  static const IconData error = MaterialSymbols.error_rounded;

  /// Close
  static const IconData close = MaterialSymbols.close_rounded;

  /// Empty / inbox
  static const IconData empty = MaterialSymbols.inbox_rounded;

  /// More horizontal
  static const IconData more = MaterialSymbols.more_horiz_rounded;

  /// Medical services
  static const IconData medical = MaterialSymbols.medical_services_rounded;

  /// Description / catatan
  static const IconData description = MaterialSymbols.description_rounded;

  /// Payment / tagihan
  static const IconData payment = MaterialSymbols.payments_rounded;

  /// Tunai / cash payment
  static const IconData tunai = MaterialSymbols.payments_rounded;

  /// QRIS / QR code payment
  static const IconData qris = MaterialSymbols.qr_code_rounded;

  /// Computer / system
  static const IconData computer = MaterialSymbols.computer_rounded;

  /// Compare / selisih
  static const IconData compare = MaterialSymbols.compare_rounded;

  // ─── Dashboard Summary ────────────────────────────────────────────────────

  /// Wallet / omzet — untuk ringkasan omzet hari ini
  static const IconData wallet = MaterialSymbols.wallet_rounded;

  /// Calendar / jadwal — untuk ringkasan jadwal hari ini
  static const IconData jadwalSummary = MaterialSymbols.calendar_today_rounded;

  /// Receipt / transaksi — untuk ringkasan transaksi hari ini
  static const IconData receiptSummary = MaterialSymbols.receipt_long_rounded;

  /// User check / hadir — untuk ringkasan hadir hari ini
  static const IconData hadirSummary = MaterialSymbols.check_circle_rounded;

  /// Check circle
  static const IconData checkCircle = MaterialSymbols.check_circle_rounded;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/ui/app_symbols.dart
git commit -m "feat(icons): create AppSymbols wrapper with Material Symbols rounded"
```

---

## TASK 2: Update pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Update pubspec.yaml**

Hapus:
```yaml
hugeicons: ^1.1.6
```

Tambah:
```yaml
material_symbols_icons: ^4.3000.0
pdf: ^3.11.0
printing: ^5.13.0
csv: ^6.0.0
```

Run: `flutter pub get`

Expected: Resolves to new packages, hugeicons removed from .dart_tool.

- [ ] **Step 2: Commit**

```bash
git add pubspec.yaml
git commit -m "chore(deps): replace hugeicons with material_symbols_icons, add pdf/printing/csv"
```

---

## TASK 3: Migrate transaksi_form_page.dart Icons

**Files:**
- Modify: `lib/pages/transaksi_form_page.dart` (lines 527, 532)

- [ ] **Step 1: Swap HugeIcon to Icon in SegmentedButton**

Change from:
```dart
icon: HugeIcon(icon: AppIcons.tunai, size: 18),
icon: HugeIcon(icon: AppIcons.qris, size: 18),
```

To:
```dart
icon: Icon(AppSymbols.tunai, size: 18),
icon: Icon(AppSymbols.qris, size: 18),
```

Also remove the direct `hugeicons` import at the top of the file — keep `AppIcons` import only if file uses `app_icons.dart` for other references, otherwise remove that too.

- [ ] **Step 2: Verify with flutter analyze**

```bash
flutter analyze lib/pages/transaksi_form_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/pages/transaksi_form_page.dart
git commit -m "refactor(icons): swap tunai/qris icons to AppSymbols in transaksi form"
```

---

## TASK 4: Migrate Semua Halaman Sekaligus

**Files:** 30+ page files (see FILE MAP above)

**Approach:** One file per batch. For each file:
1. Remove `import 'package:hugeicons/hugeicons.dart';`
2. Replace all `HugeIcon(icon: AppIcons.xxx, ...)` with `Icon(AppSymbols.xxx, ...)`
3. Replace all `import 'package:klinik_mobile_app/core/ui/app_icons.dart'` usages if file only uses icons (keep if file uses other AppIcons utilities)
4. Add `import 'package:klinik_mobile_app/core/ui/app_symbols.dart';`

**Batch grouping (each batch = 5-8 files, commit after each batch):**

**Batch 4a — Dashboard & Login:**
- `lib/pages/dashboard_page.dart` (12 icons, swap all HugeIcons)
- `lib/pages/login_page.dart`
- `lib/pages/login_layouts.dart`
- `lib/widgets/app_error_view.dart`
- `lib/widgets/app_empty_view.dart`

**Batch 4b — Obat Pages:**
- `lib/pages/obat_page.dart`
- `lib/pages/obat_form_page.dart`
- `lib/pages/obat_detail_page.dart`
- `lib/pages/obat_hub_page.dart`
- `lib/pages/obat_masuk_page.dart`
- `lib/pages/obat_masuk_detail_page.dart`
- `lib/pages/obat_masuk_tanggal_form_page.dart`

**Batch 4c — Obat Keluar Pages:**
- `lib/pages/obat_keluar_page.dart`
- `lib/pages/obat_keluar_detail_page.dart`
- `lib/pages/obat_keluar_form_page.dart`
- `lib/pages/obat_keluar_item_row.dart`
- `lib/pages/obat_keluar_tanggal_form_page.dart`

**Batch 4d — Pasien & Kehadiran:**
- `lib/pages/pasien_detail_page.dart`
- `lib/pages/pasien_form_page.dart`
- `lib/pages/kehadiran_tab_content.dart`
- `lib/pages/kehadiran_detail_page.dart`
- `lib/pages/kehadiran_form_page.dart`

**Batch 4e — Transaksi & Laporan:**
- `lib/pages/laporan_page.dart`
- `lib/pages/kunjungan_form_page.dart`
- `lib/pages/sinkronisasi_stok_page.dart`
- `lib/pages/sinkronisasi_stok_form_page.dart`
- `lib/pages/sinkronisasi_stok_panels.dart`

**Batch 4f — Auth Pages:**
- `lib/pages/forgot_password_page.dart`
- `lib/pages/reset_password_page.dart`

**For each file, the replacement pattern is:**
```
Before:
import 'package:hugeicons/hugeicons.dart';
import 'package:klinik_mobile_app/core/ui/app_icons.dart';
...
HugeIcon(icon: AppIcons.xxx, color: ..., size: ...)

After:
import 'package:klinik_mobile_app/core/ui/app_symbols.dart';
...
Icon(AppSymbols.xxx, color: ..., size: ...)
```

**Note:** Some files use both `AppIcons` (for icons) AND other utilities from `app_icons.dart` (unlikely but possible). If a file uses `AppIcons` for non-icon purposes, keep the `app_icons.dart` import alongside the new `app_symbols.dart` import.

**After each batch:**
- Run: `flutter analyze`
- Expected: No new errors
- Commit with message: `refactor(icons): batch N — swap HugeIcons to AppSymbols`

- [ ] **Step 1: Execute all batches (4a through 4f)**
- [ ] **Step 2: Final cleanup — grep for any remaining HugeIcon usage**

```bash
grep -rn "HugeIcon\|import.*hugeicons" lib/ --include="*.dart"
```
Expected: Zero results.

- [ ] **Step 3: Run full analyze + test**

```bash
flutter analyze
flutter test
```
Expected: No errors, all 173 tests pass.

- [ ] **Step 4: Commit final batch**

```bash
git add -A && git commit -m "refactor(icons): remove hugeicons, migrate all pages to AppSymbols"
```

---

## TASK 5: Deprecate app_icons.dart

**Files:**
- Modify: `lib/core/ui/app_icons.dart`

- [ ] **Step 1: Add deprecation notice at top of file**

Change the file header comment to:
```dart
// ⚠️ DEPRECATED — Gunakan AppSymbols untuk semua icon baru.
// File ini akan dipertahankan untuk backward compatibility.
// DO NOT add new icons here. Gunakan AppSymbols.
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/ui/app_icons.dart
git commit -m "docs(icons): deprecate app_icons.dart, migrate to AppSymbols"
```

---

## TASK 6: Schema — ALTER TABLE transaksi (status_lunas)

**Files:**
- Modify: Supabase schema (via SQL)

**⚠️ MANDATORY: Show SQL first, wait for "LANJUT" before executing.**

- [ ] **Step 1: Show SQL to user**

```sql
ALTER TABLE public.transaksi
ADD COLUMN IF NOT EXISTS status_lunas
  TEXT NOT NULL DEFAULT 'lunas'
  CHECK (status_lunas IN ('lunas', 'belum_lunas'));

COMMENT ON COLUMN public.transaksi.status_lunas
  IS 'lunas | belum_lunas. Default lunas (semua data lama langsung lunas)';
```

**Explanation:** Menambah kolom `status_lunas` ke tabel `transaksi` untuk tracking piutang (pasien yang belum lunas). Default `lunas` agar semua transaksi lama langsung dianggap lunas — tidak ada breaking change. CHECK constraint memastikan hanya value yang valid yang bisa disimpan.

- [ ] **Step 2: Wait for user to type "LANJUT"**
- [ ] **Step 3: Execute via Supabase MCP**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat(schema): add status_lunas column to transaksi table"
```

---

## TASK 7: Schema — CREATE TABLE kas_keluar

**Files:**
- Modify: Supabase schema (via SQL)

**⚠️ MANDATORY: Show SQL first, wait for "LANJUT" before executing.**

- [ ] **Step 1: Show SQL to user**

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

**Explanation:** Tabel untuk mencatat pengeluaran operasional klinik (pembelian obat, listrik, gaji, dll). RLS policy memastikan hanya owner yang bisa baca/tulis. CHECK constraint memastikan jumlah > 0.

- [ ] **Step 2: Wait for user to type "LANJUT"**
- [ ] **Step 3: Execute via Supabase MCP**
- [ ] **Step 4: Commit**

```bash
git commit -m "feat(schema): create kas_keluar table with RLS policy"
```

---

## TASK 8: Create kas_keluar Model & Repository

**Files:**
- Create: `lib/data/models/kas_keluar_model.dart`
- Create: `lib/data/repositories/kas_keluar_repository.dart`
- Test: `test/data/models/kas_keluar_model_test.dart`
- Test: `test/data/repositories/kas_keluar_repository_test.dart`

**Model fields:** `id`, `tanggal`, `kategori`, `jumlah`, `keterangan`, `idAdmin`, `createdAt`

**Repository methods:**
- `KasKeluarRepository.getAll()` → `List<KasKeluarModel>`
- `KasKeluarRepository.getByRange(DateTime start, DateTime end)` → `List<KasKeluarModel>`
- `KasKeluarRepository.insert(KasKeluarModel)` → returns inserted id
- `KasKeluarRepository.delete(int id)` → void

Follow existing patterns from `obat_masuk_repository.dart` and `obat_keluar_repository.dart`.

- [ ] **Step 1: Write tests**
- [ ] **Step 2: Run tests (should fail — no model yet)**
- [ ] **Step 3: Implement model + repository**
- [ ] **Step 4: Run tests (should pass)**
- [ ] **Step 5: Commit**

```bash
git add lib/data/models/kas_keluar_model.dart lib/data/repositories/kas_keluar_repository.dart test/data/models/kas_keluar_model_test.dart test/data/repositories/kas_keluar_repository_test.dart
git commit -m "feat(kas): add kas_keluar model and repository"
```

---

## TASK 9: Add status_lunas to TransaksiModel

**Files:**
- Modify: `lib/data/models/transaksi_model.dart`

- [ ] **Step 1: Add `statusLunas` field to TransaksiModel**

```dart
class TransaksiModel {
  // ... existing fields
  final String statusLunas; // 'lunas' | 'belum_lunas', default 'lunas'

  TransaksiModel({
    // ...
    this.statusLunas = 'lunas',
  });
}
```

- [ ] **Step 2: Update fromMap to parse status_lunas**

```dart
factory TransaksiModel.fromMap(Map<String, dynamic> map) {
  return TransaksiModel(
    // ... existing fields
    statusLunas: map['status_lunas'] as String? ?? 'lunas',
  );
}
```

- [ ] **Step 3: Update toMap to serialize status_lunas**

- [ ] **Step 4: Add existing test or verify tests pass**

- [ ] **Step 5: Commit**

```bash
git add lib/data/models/transaksi_model.dart
git commit -m "feat(model): add status_lunas field to TransaksiModel"
```

---

## TASK 10: Final Verification

- [ ] **Step 1: Full flutter analyze**

```bash
flutter analyze
```
Expected: No issues.

- [ ] **Step 2: Full flutter test**

```bash
flutter test
```
Expected: All tests pass (173+).

- [ ] **Step 3: Grep verification**

```bash
grep -rn "HugeIcon\|import.*hugeicons" lib/
```
Expected: Zero results (excluding app_icons.dart deprecation comment).

- [ ] **Step 4: Schema verification (via MCP)**

Query to run:
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'transaksi'
  AND column_name = 'status_lunas';
```

Query to run:
```sql
SELECT table_name, row_security
FROM information_schema.tables
WHERE table_name = 'kas_keluar';
```

- [ ] **Step 5: Push to remote**

```bash
git push origin latihan-plugin
```

---

## DEPENDENCY ORDER

```
Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 6/7 → Task 8 → Task 9 → Task 10
  (AppSymbols)  (pubspec)  (form swap)  (pages)  (deprecate)  (SQL)    (model)   (model)  (verify)
```

Tasks 6 and 7 are blocked by user input ("LANJUT") — do not execute SQL until user confirms.