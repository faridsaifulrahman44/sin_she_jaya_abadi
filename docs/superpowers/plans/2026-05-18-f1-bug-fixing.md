# F1 Bug Fixing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perbaiki 3 bug existing (deleteFotoObat, test harness, ikon QRIS/Tunai) dengan perubahan minimal

**Architecture:** Pendekatan minimal — hanya fix bug yang ditemukan, tidak refactor atau ubah arsitektur yang sudah bekerja

**Tech Stack:** Flutter, Dart, Supabase Flutter SDK, flutter_test

---

## File Structure

### Files to Modify:
- `lib/data/repositories/obat_repository.dart:401-416` — fix `deleteFotoObat()` method
- `lib/pages/transaksi_form_page.dart:519-540` — verifikasi ikon QRIS/Tunai (jika perlu ganti)

### Files to Audit (no changes if tests pass):
- `test/**/*.dart` — 23 test files untuk audit

### Files to Create (if needed):
- `lib/test_helpers/mock_repositories.dart` — tambah mock jika ada test yang perlu

---

## Task 1: Fix deleteFotoObat() — Clear foto_key + foto_url

**Files:**
- Modify: `lib/data/repositories/obat_repository.dart:401-416`

- [ ] **Step 1: Baca method deleteFotoObat() saat ini**

Run:
```bash
grep -A 15 "deleteFotoObat" lib/data/repositories/obat_repository.dart
```

Expected: Method hanya clear `foto_url`, tidak clear `foto_key`

- [ ] **Step 2: Ubah deleteFotoObat() untuk clear foto_key + foto_url**

File: `lib/data/repositories/obat_repository.dart`

Ubah line 410-412 dari:
```dart
// Clear foto_url in obat record
await _client
    .from('obat')
    .update({'foto_url': null}).eq('id_obat', idObat);
```

Menjadi:
```dart
// Clear foto_key + foto_url in obat record
await _client.from('obat').update({
  'foto_key': null,
  'foto_url': null,
}).eq('id_obat', idObat);
```

- [ ] **Step 3: Verifikasi perubahan dengan flutter analyze**

Run:
```bash
flutter analyze lib/data/repositories/obat_repository.dart
```

Expected: No issues found

- [ ] **Step 4: Commit perubahan**

```bash
git add lib/data/repositories/obat_repository.dart
git commit -m "fix: deleteFotoObat() clear foto_key + foto_url"
```

---

## Task 2: Audit Test Files — Identifikasi Test yang Gagiles:**
- Audit: `test/**/*.dart` (23 files)

- [ ] **Step 1: Jalankan semua test dan catat yang gagal**

Run:
```bash
flutter test --reporter expanded > test_results.txt 2>&1
```

Expected: Beberapa test mungkin gagal karena Supabase.instance

- [ ] **Step 2: Analisis test_results.txt — identifikasi pola kegagalan**

Run:
```bash
grep -E "(FAILED|ERROR)" test_results.txt
```

Expected: List test yang gagal dengan error message

- [ ] **Step 3: Kategorikan test yang gagal**

Buat file sementara `test_audit.md` dengan format:

```markdown
# Test Audit Results

## Tests yang GAGAL karena Supabase.instance:
- [ ] test/path/to/test.dart — error: "Supabase.instance not initialized"

## Tests yang GAGAL karena bug logika:
- [ ] test/path/to/test.dart — error: "assertion failed"

## Tests yang PASS:
- [x] test/path/to/test.dart — OK
```

- [ ] **Step 4: Review test_audit.md**

Pastikan semua 23 test files sudah dikategorikan.

Expected: Daftar lengkap test dengan status

---

## Task 3: Fix Test yang Gagal karena Supabase.instance

**Files:**
- Modify: Test files yang gagal karena Supabase.instance (berdasarkan Task 2)
- Modify: `lib/test_helpers/mock_repositoriesjika perlu tambah mock)

- [ ] **Step 1: Untuk setiap test yang gagal karena Supabase.instance**

Contoh: Jika `test/features/stok/stock_service_test.dart` gagal:

Cek apakah test sudah pakai mock:
```bash
grep -n "MockRepositories\|mock" test/features/stok/stock_service_test.dart
```

Expected: Jika sudah pakai mock → skip, jika belum → lanjut ke Step 2

- [ ] **Step 2: Tambah mock repository jika diperlukan**

File: `lib/test_helpers/mock_repositories.dart`

Jika test pakai repository yang belum ada mock-nya, tambahkan:

```dart
class _MockPasienRepository implements PasienRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}
```

Dan tambahkan ke `MockRepositories` class:

```dart
class MockRepositories {
  // ... existing mocks ...
  late final PasienRepository pasien;

  MockRepositories() {
    // ... existing mocks ...
    pasien = _MockPasienRepository();
  }
}
```

- [ ] **Step 3: Update test file untuk pakai mock**

Contoh untuk test yang depend ke repository:

```dart
void main() {
  gr('Feature test', () {
    late FeatureService service;
    late MockRepositories mocks;

    setUp(() {
      mocks = MockRepositories();
      service = FeatureService(
        repository: mocks.pasien,
      );
    });

    test('should validate input', () {
      // test code
    });
  });
}
```

- [ ] **Step 4: Jalankan test yang sudah diperbaiki**

Run:
```bash
flutter test test/path/to/fixed_test.dart
```

Expected: Test pass

- [ ] **Step 5: Commit perubahan test**

```bash
git add lib/test_helpers/mock_repositories.dart test/path/to/fixed_test.dart
git commit -m "test: fix test harness untuk [nama_test]"
```

- [ ] **Step 6: Ulangi Step 1-5 untuk semua test yang gagal**

Catatan: Jika test gagal karena bug logika (bukan Supabase.instance), **JANGAN diperbaiki** — laporkan sebagai pre-existing issue.

---

## Task 4: Verifikasi Visual Ikon QRIS/Tunai

**Files:**
- Verify: `lib/pages/transaksi_form_page.dart:519-540`
- Modify (jika perlu): `lib/pages/transaksi_form_page.dart:519-540`

- [ ] **Step 1: Cek kode ikon saat ini**

Run:
```bash
grep -A 15 "SegmentedButton<MetodeBayarTransaksi>" lib/pages/transaksi_form_page.dart
```

Expected: Sudah pakai `Icons.ps_outlined` dan `Icons.qr_code_2_outlined`

- [ ] **Step 2: Jalankan app di emulator/HP untuk verifikasi visual**

Run:
```bash
flutter run
```

Navigate ke: Dashboard → Tambah Transaksi → Lihat SegmentedButton metode bayar

Expected: Ikon 💵 (Tunai) dan 📱 (QRIS) muncul di kiri label

- [ ] **Step 3a: Jika ikon SUDAH muncul dengan benar**

**TIDAK ADA PERUBAHAN KODE** — lanjut ke Step 4

- [ ] **Step 3b: Jika ikon TIDAK muncul atau tidak sesuai**

Ganti dengan ikon dari HugeIcons:

File: `lib/pages/transaksi_form_page.dart`

Ubah line 519-540:

```dart
SegmentedButton<MetodeBayarTransaksi>(
  segments: [
    ButtonSegment(
      value: MetodeBayarTransaksi.cash,
      label: Text('Tunai'),
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedMoney02,
        color: cprimary(context),
        size: 18,
      ),
    ),
    ButtonSegment(
      value: MetodeBayarTransaksi.qris,
      label: Text('QRIS'),
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedQrCode,
        color: cprimary(context),
        size: 18,
      ),
    ),
  ],
  // ... rest of code
)
```

- [ ] **Step 4: Commit perubahan (jika ada)**

Jika ada perubahan di Step 3b:
```bash
git add lib/pages/transaksi_form_page.dart
git commit -m "fix: ganti ikon QRIS/Tunai dengan HugeIcons"
```

Jika tidak ada perubahan:
```bash
# No commit needed — ikon sudah benar
```

---

## Task 5: Verifikasi Final — Analyze & Test

**Files:**
- All modified files

- [ ] **Step 1: Jalankan flutter analyze**

Run:
```bash
flutter analyze
```

Expected: No issues found (0 error, 0 warning)

- [ ] **Step 2: Jalankan semua test**

Run:
```bash
flutter test --reporter expanded
```

Expected: Semua test pass, atau pre-existing issue yang sudah dilaporkan

- [ ] **Step 3: Buat laporan hasil**

Buat file `F1_BUG_FIXING_REPORT.md`:

```markdown
# F1 Bug Fixing Report

**Tanggal:** 2026-05-18
**Branch:** latihan-plugin

---

## ✅ File yang diubah:

- `lib/data/repositories/obat_repository.dart` — fix deleteFotoObat() clear foto_key + foto_url
- `lib/test_helpers/mock_repositories.dart` — [jika ada perubahan, sebutkan]
- `test/path/to/test.dart` — [jika ada perubahan, sebutkan]
- `lib/pages/transaksi_form_page.dart` — [jika ada perubahan, sebutkan]

---

## 🔒 Yang TIDAK diubah:

- uploadFotoObat() — sudah benar
- ObatFotoResolver — sudah benar
- schema.sql, RLS, RPC, trigger — tidak disentuh
- Logika stok — tidak disentuh
- Auth/role — tidak disentuh

---

## 🧪 Hasil analyze & test:

### flutter analyze:
```
[paste output di sini]
```

### flutter test:
```
[paste summary: X passed, Y failed]
```

---

## ⚠️ Isu pre-existing yang perlu diketahui:

- [Jika ada test yang gagal karena Supabase.instance, dilaporkan di sini]
- [Jika ada test yang gagal karena bug logika, dilaporkan di sini]

---

## 📸 Screenshot Verifikasi Ikon QRIS/Tunai:

[Jika ada screenshot, attach di sini]

---

## ✅ Checklist Final:

- [x] deleteFotoObat() sudah clear foto_key + foto_url
- [x] Test harness audit selesai
- [x] Ikon QRIS/Tunai sudah diverifikasi
- [x] flutter analyze → 0 error
- [x] flutter test → semua pass (atau pre-existing issue dilaporkan)
```

- [ ] **Step 4: Commit laporan**

```bash
git add F1_BUG_FIXING_REPORT.md
git commit -m "docs: F1 bug fixing report"
```

- [ ] **Step 5: Push ke remote (jika diminta)**

```bash
git push origin latihan-plugin
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ Bug 1 (deleteFotoObat) → Task 1
- ✅ Bug 2 (test harness) → Task 2, 3
- ✅ Bug 3 (ikon QRIS/Tunai) → Task 4
- ✅ Verifikasi final → Task 5

**Placeholder scan:**
- ✅ Tidak ada "TBD", "TODO", "implement later"
- ✅ Semua step punya kode konkret atau command eksplisit
- ✅ Tidak ada "add appropriate error handling" tanpa kode

**Type consistency:**
- ✅ `deleteFotoObat()` signature konsisten di semua task
- ✅ `MockRepositories` pattern konsisten
- ✅ File path konsisten

---

## Execution Notes

- **Task 1** bisa dikerjakan langsung — tidak depend ke task lain
- **Task 2** harus selesai dulu sebelum Task 3 (perlu tahu test mana yang gagal)
- **Task 3** depend ke Task 2 (audit results)
- **Task 4** bisa dikerjakan paralel dengan Task 1-3
- **Task 5** harus terakhir (verifikasi semua perubahan)

**Estimasi waktu:**
- Task 1: 5 menit
- Task 2: 10 menit
- Task 3: 15-30 menit (tergantung jumlah test yang gagal)
- Task 4: 5-10 menit
- Task 5: 10 menit

**Total:** ~45-65 menit
