# F8 Laporan Owner 3-Tab — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans

**Goal:** Rewrite `LaporanPage` dengan 3 tab (Harian/Bulanan/Tahunan) + grafik fl_chart + Top 10 Obat + Export CSV/PDF.

**Architecture:** Full rewrite `laporan_page.dart` — `DefaultTabController` + 3 `StatelessWidget` tabs. Data aggregation dari `LaporanRepository` + `LaporanAggregator`. Tidak ada page baru.

**Tech Stack:** Flutter/Dart, `fl_chart`, `csv`, `pdf`, `printing`, `EmilDesign`, `HugeIcons`

---

## File yang Diedit

- `pubspec.yaml` — tambah `csv`, `pdf`, `printing`
- `lib/data/models/top_obat_item.dart` — model baru
- `lib/pages/laporan_page.dart` — full rewrite
- `lib/core/utils/csv_exporter.dart` — utility baru
- `lib/core/utils/pdf_exporter.dart` — utility baru

---

## Task 1: Setup — Packages + Model

**Files:** Modify: `pubspec.yaml` + Create: `lib/data/models/top_obat_item.dart`

- [ ] Tambahkan 3 packages ke `pubspec.yaml` dependencies:
  ```yaml
  csv: ^6.0.0
  pdf: ^3.11.1
  printing: ^5.13.4
  ```
- [ ] Run `flutter pub get`
- [ ] Buat `lib/data/models/top_obat_item.dart`:
  ```dart
  class TopObatItem {
    const TopObatItem({
      required this.rank,
      required this.namaObat,
      required this.jumlahTerjual,
      required this.totalNominal,
      required this.rankType,
    });
    final int rank;
    final String namaObat;
    final int jumlahTerjual;
    final double totalNominal;
    final String rankType; // gold, silver, bronze, plain
  }
  ```

**Verify:** `flutter pub get` succeeds

---

## Task 2: CSV Exporter

**Files:** Create: `lib/core/utils/csv_exporter.dart`

- [ ] Export `CsvExporter` class dengan static method:
  - `exportLaporanHarian(List<DailyIncomePoint> data, String periodLabel) → String`
  - `exportLaporanBulanan(List<DailyIncomePoint> data, String monthLabel) → String`
  - `exportLaporanTahunan(Map<String, List<DailyIncomePoint>> monthlyData, String year) → String`
- [ ] Pakai `csv` package `ListToCsvConverter`

---

## Task 3: PDF Exporter

**Files:** Create: `lib/core/utils/pdf_exporter.dart`

- [ ] Export `PdfExporter` class dengan static method:
  - `exportLaporan(LaporanSummary summary, String periodLabel) → Uint8List`
- [ ] Pakai `pdf` + `printing` packages
- [ ] Document sederhana: header "SinShe Jaya Abadi", table metrik, footer copyright

---

## Task 4: Rewrite LaporanPage — Shell + TabBar

**Files:** Modify: `lib/pages/laporan_page.dart`

- [ ] Ganti `LaporanPage` state → `DefaultTabController(length: 3)` di level page
- [ ] Tambahkan `AppTabs` row di atas `TabBarView`
- [ ] Buat 3 tab widget classes:
  - `_LaporanHarianTab` (StatelessWidget)
  - `_LaporanBulananTab` (StatelessWidget)
  - `_LaporanTahunanTab` (StatelessWidget)
- [ ] Masing-masing terima `LaporanSummary` + `DateTime start/end` sebagai params
- [ ] Pattern: `TabBarView` → `children: [_LaporanHarianTab(...), _LaporanBulananTab(...), _LaporanTahunanTab(...)]`

**Code skeleton:**

```dart
class _LaporanPageState extends State<LaporanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'harian'; // default tab 0

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedFilter = ['harian','bulanan','tahunan'][_tabController.index];
        });
        _loadData();
      }
    });
    _checkAccess();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  // ... existing _checkAccess, _loadData tetap
  // _initDateRange update switch case untuk harian/bulanan/tahunan
}
```

---

## Task 5: LaporanHarianTab

**Files:** Modify: `lib/pages/laporan_page.dart` — dalam class `_LaporanHarianTab`

- [ ] `StatelessWidget` dengan param: `LaporanSummary summary, DateTime startDate`
- [ ] DatePicker row: `OutlinedButton` → `showDatePicker` single date
- [ ] `lap-card` — Total Penjualan + Jumlah Transaksi (2-col stat grid)
- [ ] `lap-card` — Breakdown Obat/Praktek
- [ ] `lap-card` — BarChart harian (fl_chart, 1 data point = 1 transaksi)
  - X: jam (0-23), Y: nominal. Group per jam. Max 10 bar visible.
- [ ] `bd-row` — Tunai | QRIS | Best Day
- [ ] Export row: CSV + Thermal buttons

---

## Task 6: LaporanBulananTab

**Files:** Modify: `lib/pages/laporan_page.dart` — dalam class `_LaporanBulananTab`

- [ ] `StatelessWidget` dengan param: `LaporanSummary summary, DateTime startDate, DateTime endDate`
- [ ] MonthPicker: `OutlinedButton` → `showDatePicker` dengan `initialDateRange`
- [ ] `lap-card` — Total + Transaksi
- [ ] `lap-card` — Breakdown Obat/Praktek
- [ ] `lap-card` — BarChart bulanan (1 data point = 1 hari)
  - X: day 1..max, Y: nominal. Full month.
- [ ] `bd-row` — Breakdown % | Tunai | QRIS | Best Day
- [ ] Top 10 Obat list (TopObatItem list)
- [ ] Section "Operasional" + 4 op-cards (Obat Masuk, Obat Keluar, Sinkronisasi, Pasien Baru)
- [ ] Export row: CSV + Thermal

---

## Task 7: LaporanTahunanTab

**Files:** Modify: `lib/pages/laporan_page.dart` — dalam class `_LaporanTahunanTab`

- [ ] `StatelessWidget` dengan param: `LaporanSummary summary, DateTime startDate`
- [ ] YearPicker: `DropdownButton<int>` (2024..current year)
- [ ] `lap-card` — Total Penjualan YTD + Total Transaksi
- [ ] `lap-card` — Obat / Praktek count
- [ ] `lap-card` — BarChart tahunan (1 data point = 1 bulan, Jan–Des)
- [ ] `bd-row` — Per Etalase (from etalase breakdown)
- [ ] `lap-card` — Stok Overview: Habis / Menipis / Aman
- [ ] Export row: CSV only

---

## Task 8: Verify

**Files:** Analyze: `lib/pages/laporan_page.dart`, `lib/core/utils/csv_exporter.dart`, `lib/core/utils/pdf_exporter.dart`

- [ ] Run `flutter pub get` — pastikan packages resolve
- [ ] Run `flutter analyze lib/pages/laporan_page.dart` — 0 errors
- [ ] Run `flutter analyze` — pastikan tidak ada regressions

---

## Task 9: Commit

```bash
git add pubspec.yaml lib/data/models/top_obat_item.dart lib/pages/laporan_page.dart lib/core/utils/csv_exporter.dart lib/core/utils/pdf_exporter.dart
git commit -m "feat(F8): rewrite LaporanPage — 3-tab (Harian/Bulanan/Tahunan) + fl_chart + Top 10 + CSV/PDF export"
```
