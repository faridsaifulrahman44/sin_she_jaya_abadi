# Spec: F8 — Laporan Owner (3-Tab + Grafik + Top 10 + Export)

Tanggal: 2026-05-31
Status: Approved — siap implementasi

---

## Ringkasan

Redesign `LaporanPage` dengan 3 tab (Harian / Bulanan / Tahunan) + grafik fl_chart + Top 10 Obat + Export CSV & PDF. Semua data Owner-only (`role: owner`).

---

## Struktur Tab

```
LaporanPage
├── TabBar (Harian | Bulanan | Tahunan)
├── Tab 1: Harian
│   ├── DatePicker (tanggal tunggal)
│   ├── lap-card: Total Penjualan + Jumlah Transaksi
│   ├── lap-card: Breakdown Obat/Praktek
│   ├── bar-chart (fl_chart BarChart): tren per jam (0–23)
│   ├── bd-row: Tunai, QRIS, Best Day
│   └── export-row (CSV + Thermal)
├── Tab 2: Bulanan
│   ├── MonthPicker (bulan + tahun)
│   ├── lap-card: Total + Transaksi
│   ├── lap-card: Breakdown Obat/Praktek
│   ├── bar-chart (fl_chart): tren harian (day 1–max)
│   ├── bd-row: Breakdown % + Tunai + QRIS + Best Day
│   ├── top-list: Top 10 Obat (jumlah + nominal)
│   ├── section-hdr: "Operasional — [Bulan]"
│   ├── op-card × 4: Obat Masuk, Obat Keluar, Sinkronisasi, Pasien Baru
│   └── export-row (CSV + Thermal)
├── Tab 3: Tahunan
│   ├── YearPicker
│   ├── lap-card: Total Penjualan YTD + Total Transaksi
│   ├── lap-card: Obat / Praktek count
│   ├── bar-chart (fl_chart): tren bulanan (Jan–Des)
│   ├── bd-row: Per Etalase + Pasien Baru
│   ├── lap-card: Stok Overview (Habis / Menipis / Aman)
│   └── export-row (CSV + Thermal)
```

---

## Data yang Diperlukan

### Query Supabase Existing (via LaporanRepository)

`LaporanRepository.getReportData(startDate, endDate)` return:

| Field | Pakai |
|---|---|
| `transaksiPeriode` | totals, count, cash/qris, best day |
| `transaksiItemsAllTime` | Top 10 aggregation |
| `obatAllTime` | Stok overview (habis/menipis) |

**Tidak perlu query baru** — agregasi dilakukan di Dart dari data yang sudah ada.

### Top 10 Obat

1. Filter `transaksiItemsAllTime` → item dengan `idObat` yang punya `etalase` 1 atau 2 (obat Ready Stock) dalam periode
2. Group by `idObat` / `namaObat`
3. Sum `jumlah` terjual + `subtotal`
4. Sort by subtotal desc → take 10

Model baru `TopObatItem`:

```dart
class TopObatItem {
  const TopObatItem({
    required this.rank,
    required this.namaObat,
    required this.jumlahTerjual,
    required this.totalNominal,
    required this.rankType, // gold, silver, bronze, plain, p5..p10
  });
  final int rank;
  final String namaObat;
  final int jumlahTerjual;
  final double totalNominal;
  final String rankType;
}
```

### Operasional Bulanan (B/W)

Dari `LaporanDataBundle`:

| Metrik | Source |
|---|---|
| Total Obat Masuk | `obat_masuk` count in period |
| Total Obat Keluar (non-jual) | `obat_keluar` count in period |
| Koreksi Sinkronisasi | `sinkronisasi_stok` count in period |
| Pasien Baru (periode) | `pasienPeriode.where(p.createdAt >= start)` |

Untuk 3 pertama: perlu query terpisah atau agregasi. Jika belum ada repo method → skip dulu, tampilkan "N/A" dengan placeholder.

### Stok Overview (Tahunan)

Dari `obatAllTime`:
- **Habis**: `stok == 0`
- **Menipis**: `0 < stok <= stok_minimum`
- **Aman**: `stok > stok_minimum`

---

## Komponen UI

### Tab Bar (`lap-tabs`)

- Container dengan `background: surface`, `border-radius: r-md`, `padding: 6px`, `gap: 4px`
- 3 `lap-tab`: `flex: 1`, `font-size: 12px`, `font-weight: 600`
- Active: `background: white`, `color: blue`, `box-shadow: shadow-sm`
- Pakai `DefaultTabController` + `TabBarView`

### Card (`lap-card`)

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.md),
    boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 6, offset: Offset(0, 2))],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: EmilDesign.csurface(context),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.md), topRight: Radius.circular(AppRadius.md)),
        ),
        child: Text(headerText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      Padding(padding: EdgeInsets.all(12), child: content),
    ],
  ),
)
```

### Stat Grid (`lap-stat-row`)

- `GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: NeverScrollableScrollPhysics)`
- Value: 22px, font-weight 800
- Label: 10px, muted

### Bar Chart (fl_chart)

```dart
BarChart(
  BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: maxValue * 1.2,
    barTouchData: BarTouchData(enabled: false),
    titlesData: FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
          // Harian: "00","06","12","18" jam
          // Bulanan: "1","5","10","15","20","25","31"
          // Tahunan: "Jan","Feb","Mar"... bulan shortcut
          return Text('$label', style: TextStyle(fontSize: 9, color: Colors.grey));
        }, reservedSize: 20),
      ),
      leftTitles: SideTitles(showTitles: false),
      topTitles: SideTitles(showTitles: false),
      rightTitles: SideTitles(showTitles: false),
    ),
    borderData: FlBorderData(show: false),
    gridData: FlGridData(show: false),
    barGroups: bars.map((v) => BarChartGroupData(
      x: v.index,
      barRods: [BarChartRodData(
        toY: v.value,
        color: v.isHighlighted ? Color(0xFF00897B) : Color(0xFF90A4AE),
        width: tabIndex==0 ? 10 : 16,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
      )],
    )).toList(),
  ),
)
```

**Harian**: tampilkan hanya jam dengan transaksi, max 8-10 bar (group jam terdekat).  
**Bulanan**: semua hari dalam 1 bulan (1, 5, 10, 15, 20, 25, end).  
**Tahunan**: 12 bulan Jan–Des.

### Top 10 List (`top-list`)

```dart
ListView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  itemCount: items.length,
  itemBuilder: (ctx, i) => _TopObatRow(item: items[i]),
)

class _TopObatRow extends StatelessWidget {
  const _TopObatRow({required this.item});
  final TopObatItem item;

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    if (item.rank == 1) rankColor = Color(0xFFFFD700);
    else if (item.rank == 2) rankColor = Color(0xFFC0C0C0);
    else if (item.rank == 3) rankColor = Color(0xFFCD7F32);
    else if (item.rank == 4) rankColor = Color(0xFF00897B);
    else rankColor = Color(0xFF8D6E63);

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: Offset(0,1))],
      ),
      child: Row(
        children: [
          Container(
            width: 22, height: 22, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text('${item.rank}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.namaObat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text('${item.jumlahTerjual} terjual', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
          Text(rupiah(item.totalNominal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF00897B))),
        ],
      ),
    );
  }
}
```

### BD Row

```dart
Container(
  padding: EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), style: BorderStyle.solid, width: 1))),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]),
)
```

### Export Buttons

```dart
Row(
  children: [
    Expanded(child: OutlinedButton.icon(
      onPressed: onExportCSV,
      icon: Icon(HugeIcons(HugeIconsProp.download), size: 16),
      label: Text('Export CSV'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF00897B),
        side: BorderSide(color: Color(0xFF00897B)),
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    )),
    SizedBox(width: 8),
    Expanded(child: OutlinedButton.icon(
      onPressed: onPrintThermal,
      icon: Icon(HugeIcons(HugeIconsProp.printer), size: 16),
      label: Text('Cetak Thermal'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Color(0xFF64748B),
        side: BorderSide(color: Color(0xFFCBD5E1)),
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    )),
  ],
)
```

### Operasional Card

```dart
Container(
  margin: EdgeInsets.only(bottom: 10),
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppRadius.md),
    boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4, offset: Offset(0,1))],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
    ],
  ),
)
```

---

## Packages Tambahan (pubspec.yaml)

```yaml
dependencies:
  csv: ^6.0.0       # untuk export CSV
  pdf: ^3.11.1      # untuk export PDF
  printing: ^5.13.4 # untuk print preview PDF
```

---

## Alur Date Range

| Tab | startDate | endDate |
|---|---|---|
| Harian | `{today} 00:00:00` | `{today} 23:59:59` |
| Bulanan | `1 [bulan] [tahun] 00:00:00` | `lastDayOfMonth 23:59:59` |
| Tahunan | `1 Jan [tahun] 00:00:00` | `31 Dec [tahun] 23:59:59` |

---

## Export CSV

Format per tab:

**Harian**: `Tanggal,Jumlah Transaksi,Total Obat,Total Praktek,Total Tunai,Total QRIS,Total Penjualan`

**Bulanan**: `Tanggal,Jumlah Transaksi,Total Obat,Total Praktek,Total Tunai,Total QRIS,Total Penjualan` (satu baris per hari)

**Tahunan**: `Bulan,Jumlah Transaksi,Total Obat,Total Praktek,Total Tunai,Total QRIS,Total Penjualan`

Gunakan `csv` package `CsvToListConverter` + `ListToCsvConverter`.

---

## Export PDF

Gunakan `pdf` package untuk generate document sederhana:

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final pdf = pw.Document();
pdf.addPage(
  pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    build: (context) => [
      pw.Header(level: 0, text: 'Laporan SinShe Jaya Abadi'),
      pw.Paragraph(text: 'Periode: $periodLabel'),
      pw.SizedBox(height: 16),
      pw.Table.fromTextArray(
        headers: ['Metrik', 'Nilai'],
        data: rows,
      ),
    ],
  ),
);
// Simpan via printing package atau share
```

---

## Scope

**Termasuk:**
- Redesign full `LaporanPage` dengan 3 tab
- Bar chart dengan fl_chart
- Top 10 Obat (Ready Stock)
- Breakdown etalase + operasional card
- Export CSV + PDF
- Printer thermal button (reuse existing ReceiptPrinterServiceBW)

**Tidak Termasuk:**
- Print queue UI (F9)
- Filter tanggal kustom tambahan (bisa jadi ekspansi nanti)
- Share PDF via platform share sheet (package sudah ada `share_plus`? belum → skip)

---

## File yang Diedit/Ditambah

- `pubspec.yaml` — tambah `csv`, `pdf`, `printing`
- `lib/data/models/top_obat_item.dart` — model baru
- `lib/data/repositories/laporan_repository.dart` — tambah method `getTopObat`, `getOperasionalStats`
- `lib/pages/laporan_page.dart` — rewrite full dengan 3-tab layout
- `lib/core/utils/csv_exporter.dart` — utility export CSV
- `lib/core/utils/pdf_exporter.dart` — utility export PDF

---

## Approach

1. Tambah packages ke pubspec.yaml → `flutter pub get`
2. Buat `TopObatItem` model
3. Tambah `getTopObat()` + `getOperasionalStats()` ke `LaporanRepository`
4. Rewrite `laporan_page.dart` dengan `DefaultTabController` + 3 `StatelessWidget` tab
5. Pasang fl_chart BarChart di tab 1 & 2
6. Pasang Top 10 list di tab 2
7. Pasang Export CSV + PDF buttons
8. Flutter analyze → verify
9. Commit