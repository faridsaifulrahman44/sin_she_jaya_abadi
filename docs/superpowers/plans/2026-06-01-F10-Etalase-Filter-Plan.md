# F10 — Plan: Transaksi Etalase Filter

## Goal

Filter obat yang tampil di form transaksi berdasarkan tab aktif:
- **Tab Obat** (index 0) — tampilkan hanya obat dari **Etalase 1 & 2**
- **Tab Praktek** (index 1) — tampilkan hanya obat dari **Etalase 3**

---

## Task Breakdown

### Task 1: Tambah `getObatsByEtalase()` di `ObatRepository`
**File:** `lib/data/repositories/obat_repository.dart`

**Action:**
Tambah method baru setelah method `getObat` yang sudah ada:

```dart
/// Ambil obat yang DISPLAY saja (etalase 1 & 2 = Obat tab, etalase 3 = Praktek tab).
/// Parameter [etalases] = null berarti tampilkan semua.
/// Digunakan di TransaksiFormPage untuk memfilter berdasarkan tab aktif.
Future<List<ObatModel>> getObatsByEtalase({List<Etalase>? etalases}) {
  return guard(() async {
    final response = await _client
        .from('obat')
        .select()
        .order('nama_obat', ascending: true);

    final allObat = List<Map<String, dynamic>>.from(response)
        .map(ObatModel.fromMap)
        .toList();

    if (etalases == null || etalases.isEmpty) {
      return allObat;
    }

    return allObat
        .where((o) => etalases.contains(o.etalase))
        .toList();
  });
}
```

**Verification:**
`flutter analyze lib/data/repositories/obat_repository.dart` — zero errors.

**Done:** Method `getObatsByEtalase({List<Etalase>? etalases})` exist dan ter-export.

---

### Task 2: Refactor `_loadAvailableObats()` di `TransaksiFormPage`
**File:** `lib/pages/transaksi_form_page.dart`

**Action:**
1. Tambahkan import `ObatRepository` dan `Etalase`:

```dart
import 'package:klinik_mobile_app/data/models/obat_etalase.dart';
import 'package:klinik_mobile_app/data/repositories/obat_repository.dart';
```

2. Tambahkan field repository:

```dart
final _obatRepository = ObatRepository();
```

3. Ganti signature `_loadInitialData()` menjadi `_loadAvailableObats({List<Etalase>? allowedEtalases})`:

```dart
Future<void> _loadAvailableObats({List<Etalase>? allowedEtalases}) async {
  try {
    setState(() => _loading = true);

    // Gunakan ObatRepository (filter di query)
    // Fallback ke TransaksiRepository.getObatReadyStock() jika allowedEtalases null
    final obats = allowedEtalases != null
        ? await _obatRepository.getObatsByEtalase(etalases: allowedEtalases)
        : await _repository.getObatReadyStock();

    if (mounted) {
      setState(() {
        _availableObats = obats;
        _loading = false;
      });
    }
  } catch (error, stackTrace) {
    if (mounted) {
      setState(() => _loading = false);
      AppFeedback.showError(context, error, stackTrace);
    }
  }
}
```

4. Update `initState` untuk memanggil `_loadAvailableObats(allowedEtalases: [Etalase.etalase1, Etalase.etalase2])` (default: tab Obat).

**Verification:**
`flutter analyze lib/pages/transaksi_form_page.dart` — zero errors.

**Done:** `_loadAvailableObats(allowedEtalases: [Etalase.etalase1, Etalase.etalase2])` dipanggil saat init dan filter bekerja.

---

### Task 3: Update `_handleTabChanged()` + Cart Clear Confirmation Dialog
**File:** `lib/pages/transaksi_form_page.dart`

**Action:**
1. Definisikan konstanta filter per tab:

```dart
// Di luar State class, atau sebagai static field
static const _obatTabEtalases = [Etalase.etalase1, Etalase.etalase2];
static const _praktekTabEtalases = [Etalase.etalase3];
```

2. Update `_handleTabChanged()` untuk cek cart dan reload obat:

```dart
void _handleTabChanged() {
  final nextIndex = _tabController.index;
  if (nextIndex == _activeTabIndex) return;

  // Jika ada item di cart dan akan switch tab — minta konfirmasi
  if (_selectedObats.isNotEmpty) {
    _confirmCartClearBeforeTabSwitch(nextIndex);
  } else {
    _applyTabSwitch(nextIndex);
  }
}

Future<void> _confirmCartClearBeforeTabSwitch(int nextIndex) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Ganti Tab?'),
      content: const Text(
        'Cart akan dikosongkan jika Anda mengganti tab. Lanjutkan?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ganti Tab'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    _applyTabSwitch(nextIndex);
  } else {
    // Kembalikan tab controller ke posisi sebelumnya
    _tabController.index = _activeTabIndex;
  }
}

void _applyTabSwitch(int nextIndex) {
  setState(() {
    _activeTabIndex = nextIndex;
    if (nextIndex == 0) {
      _clearSelectedPasien();
    }
    // Kosongkan cart saat switch tab
    _selectedObats.clear();
  });

  // Load obat sesuai tab
  final allowedEtalases = nextIndex == 0
      ? _obatTabEtalases
      : _praktekTabEtalases;
  _loadAvailableObats(allowedEtalases: allowedEtalases);
}
```

3. Panggil `_applyTabSwitch` dari `initState` bukan `_loadInitialData` langsung — sehingga flow konsisten.

**Verification:**
`flutter analyze lib/pages/transaksi_form_page.dart` — zero errors.

**Done:** Switching tabs with items in cart shows confirmation dialog; cart cleared after confirmed switch.

---

### Task 4: Tambah Visual Indicator Filter Etalase di UI
**File:** `lib/pages/transaksi_form_page.dart`

**Action:**
Di dalam widget tree form (bagian atas list obat), tambahkan `Chip` atau `Container` subtitle yang menunjukkan filter aktif:

```dart
// Di dalam body listbuilder obat — di atas GridView/ListView
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  child: Row(
    children: [
      Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
      const SizedBox(width: 4),
      Text(
        _activeTabIndex == 0
            ? 'Menampilkan: Etalase 1 & 2'
            : 'Menampilkan: Etalase 3',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    ],
  ),
),
```

Letakkan di antara section header dan list obat (di dalam `Column` yang sama).

**Verification:**
Visual indicator terlihat di atas list obat saat tab aktif berubah.

**Done:** Subtitle/Chip filter indicator terlihat di UI dan berubah sesuai tab aktif.

---

### Task 5: Run Analyze & Test
**Files:** Seluruh project

**Action:**
```bash
flutter analyze
flutter test
```

**Verification:**
- `flutter analyze` — zero errors (warnings OK)
- `flutter test` — semua test pass (catat nama test yang fail jika ada pre-existing)

**Done:** Analyze clean, test pass (atau catat pre-existing failures).

---

## Dependency Analysis

```
Task 1 (ObatRepository method)
  └── Task 2 (pakai method baru dari Task 1)  ← tidak blocking, ObatRepository sudah di-import
  └── Task 4 (UI filter label, tidak dependen)

Task 2 (Refactor _loadAvailableObats)
  └── Task 3 (pakai _loadAvailableObats di _applyTabSwitch)  ← Task 3 depends on Task 2
  └── Task 4 (tidak dependen)

Task 3 (Tab switch + cart confirmation)
  └── Task 5 (verify)                                ← linear
```

**Wave 1:** Task 1, Task 2, Task 4 (parallel — edit file berbeda)
**Wave 2:** Task 3 (depends on Task 2 for `_loadAvailableObats`)
**Wave 3:** Task 5 (verify after all)

---

## Goal-Backward Verification

Setelah semua task selesai, verifikasi berikut HARUS benar:

1. **Truth:** "Tab Obat menampilkan hanya obat dari Etalase 1 & 2"
   - Bukti: Grid/list obat di tab Obat hanya berisi obat dengan `etalase.value == 'etalase1'` atau `'etalase2'`
   - Test: Buat transaksi di tab Obat, pastikan hanya etalase 1/2 yang muncul di grid

2. **Truth:** "Tab Praktek menampilkan hanya obat dari Etalase 3"
   - Bukti: Switch ke tab Praktek, grid obat berubah — hanya etalase 3
   - Test: Switch ke tab Praktek, cari obat yang diketahui etalase 1/2 — tidak muncul

3. **Truth:** "Cart dikosongkan saat switch tab"
   - Bukti: Pilih obat di tab Obat → switch ke Praktek → konfirmasi → cart kosong

4. **Truth:** "Cart clear confirmation muncul jika ada item di cart"
   - Bukti: Pilih obat di tab Obat → klik tab Praktek → dialog konfirmasi muncul

5. **Truth:** "Filter indicator terlihat di UI"
   - Bukti: Chip/subtitle "Menampilkan: Etalase 1 & 2" / "Menampilkan: Etalase 3" terlihat di atas list obat

---

## Files Summary

| Task | File | Perubahan |
|------|------|-----------|
| 1 | `lib/data/repositories/obat_repository.dart` | Tambah `getObatsByEtalase()` |
| 2 | `lib/pages/transaksi_form_page.dart` | Refactor `_loadAvailableObats()`, import `ObatRepository` + `Etalase` |
| 3 | `lib/pages/transaksi_form_page.dart` | Update `_handleTabChanged()`, tambah `_confirmCartClearBeforeTabSwitch`, `_applyTabSwitch` |
| 4 | `lib/pages/transaksi_form_page.dart` | Tambah Chip/subtitle filter indicator |
| 5 | seluruh project | `flutter analyze` + `flutter test` |

---

## Estimated Effort

- Task 1: ~10 min — method baru di repository, simple
- Task 2: ~10 min — refactor + import, simple
- Task 3: ~15 min — dialog + tab logic, ada interaksi UI
- Task 4: ~5 min — widget kecil, inline
- Task 5: ~5 min — analyze + test
- **Total estimasi: ~45 menit**
