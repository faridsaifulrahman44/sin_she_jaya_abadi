# SPEC: F1 - Bug Fixing (Pendekatan Minimal)

**Tanggal:** 2026-05-18
**Project:** Klinik Sin She Jaya Abadi
**Branch target:** `latihan-plugin` (atau buat branch baru jika perlu)
**Pendekatan:** Minimal —止まる (止)

---

## 1. Tujuan

Perbaiki 3 bug existing yang menghambat fitur bekerja optimal, dengan perubahan kode seminimal mungkin. Tidak mengubah arsitektur atau logika yang sudah bekerja.

---

## 2. Bug 1: Fix `deleteFotoObat()` — Clear `foto_key` Juga

### Kondisi Saat Ini

```dart
// obat_repository.dart — deleteFotoObat()
await _client
    .from('obat')
    .update({'foto_url': null}).eq('id_obat', idObat);
// ❌ foto_key tidak di-clear!
```

### Yang Akan Diubah

File: `lib/data/repositories/obat_repository.dart`

Method: `deleteFotoObat(int idObat, {String? fotoUrl})`

Ubah kolom yang di-clear dari `foto_url` → `foto_key` + `foto_url`:

```dart
await _client.from('obat').update({
  'foto_key': null,
  'foto_url': null,
}).eq('id_obat', idObat);
```

**Catatan:** Jangan ubah method lain — `uploadFotoObat()` sudah benar, `ObatFotoResolver` sudah benar.

---

## 3. Bug 2: Audit + Fix Test Harness

### Kondisi Saat Ini

- 23 test files ada di `test/`
- `lib/test_helpers/mock_repositories.dart` sudah ada dengan mock untuk 4 repository
- Beberapa test gagal karena Supabase.instance belum diinisialisasi di test environment

### Langkah Kerja

1. **Audit semua test files** — cek satu per satu apakah sudah menggunakan mock atau langsung depend ke Supabase real
2. **Identifikasi test yang gagal** — jalankan `flutter test` dan catat yang gagal
3. **Perbaiki hanya test yang gagal** karena Supabase real (bukan karena bug logika)
4. **TIDAK ubah** test yang sudah berhasil meskipun kode tidak ideal

### Catatan Penting (dari CLAUDE.md)

> Beberapa test gagal karena `Supabase.instance` belum diinisialisasi di test environment. Ini adalah **pre-existing issue** — bukan akibat perubahan UI/logika baru.

Jika test gagal karena ini, **laporkan secara eksplisit** — jangan dianggap sebagai regresi baru.

Test yang kemungkinan terdampak:
- `test/features/stok/stock_service_test.dart`
- `test/data/schema_contract_test.dart`

### File yang Perlu Dicek

| Test File | Status Awal | Aksi |
|-----------|-------------|------|
| `stock_service_test.dart` | Sudah pakai `MockRepositories` | Cek apakah perlu Supabase mock |
| `schema_contract_test.dart` | Baca file SQL langsung | Biasanya aman tanpa Supabase |
| Test lain yang pakai repository | Audit satu per satu | Tambah mock jika perlu |

### Tambah Mock Repository (jika diperlukan)

Jika ada test yang pakai repository tapi belum ada mock, tambah di `lib/test_helpers/mock_repositories.dart`.

Mock baru mengikuti pola yang sudah ada:

```dart
class _MockXRepository implements XRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Mock method not implemented');
}
```

---

## 4. Bug 3: Verifikasi Visual Ikon QRIS/Tunai

### Kondisi Saat Ini

`transaksi_form_page.dart` sudah pakai:
```dart
SegmentedButton<MetodeBayarTransaksi>(
  segments: [
    ButtonSegment(
      value: MetodeBayarTransaksi.cash,
      label: Text('Tunai'),
      icon: Icon(Icons.payments_outlined, size: 18),  // ✅
    ),
    ButtonSegment(
      value: MetodeBayarTransaksi.qris,
      label: Text('QRIS'),
      icon: Icon(Icons.qr_code_2_outlined, size: 18),  // ✅
    ),
  ],
)
```

### Aksi

1. **Verifikasi di emulator/HP** — ikon `payments_outlined` dan `qr_code_2_outlined` muncul dengan benar
2. Jika ikon tidak muncul → ganti dengan ikon lain dari `HugeIcons` yang sudah ada di project
3. Jika sudah muncul → **tidak ada perubahan kode**

---

## 5. Verifikasi Sebelum Selesai

### Checklist (wajib semua hijau sebelum klaim "selesai")

- [ ] `flutter analyze` → 0 error
- [ ] `flutter test` → semua test pass (atau pre-existing issue yang sudah dilaporkan)
- [ ] `deleteFotoObat()` sudah clear `foto_key` + `foto_url`
- [ ] Ikon QRIS/Tunai sudah diverifikasi tampil di UI
- [ ] Test harness audit sudah selesai

---

## 6. Batasan

### ✅ BOLEH Dilakukan
- Fix `deleteFotoObat()` agar clear `foto_key`
- Audit test files, perbaiki yang perlu
- Ganti ikon jika visual tidak sesuai

### ❌ TIDAK BOLEH Dilakukan
- Ubah `uploadFotoObat()` — sudah benar
- Ubah `ObatFotoResolver` — sudah benar
- Ubah `schema.sql`, RLS, RPC, trigger
- Ubah logika stok
- Ubah role/auth
- Hapus kolom database
- Tambah fitur baru

---

## 7. Output

Setelah semua bug diperbaiki:
1. Jalankan `flutter analyze` + `flutter test`
2. Buat laporan dengan format:

```
✅ File yang diubah:
  - lib/data/repositories/obat_repository.dart — fix deleteFotoObat() clear foto_key + foto_url

🔒 Yang TIDAK diubah:
  - uploadFotoObat(), ObatFotoResolver, schema.sql, logika stok, auth, RLS

🧪 Hasil analyze & test:
  - flutter analyze: [clean / N warning / N error]
  - flutter test: [passed / N failed]

⚠️ Isu pre-existing yang perlu diketahui:
  - [jika ada test yang gagal karena Supabase.instance, dilaporkan di sini]
```