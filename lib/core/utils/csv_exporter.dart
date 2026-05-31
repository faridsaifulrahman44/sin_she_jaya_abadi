import 'package:csv/csv.dart';
import '../../data/models/transaksi_model.dart';
import '../../features/laporan/laporan_summary.dart';

/// Exports laporan data to CSV format.
class CsvExporter {
  /// Export harian — each row = one transaksi.
  static String exportLaporanHarian(
    List<TransaksiModel> transaksi,
    String periodLabel,
  ) {
    final rows = <List<dynamic>>[
      ['Tanggal', 'Jam', 'Nominal', 'Jenis Transaksi', 'Metode Bayar'],
      ...transaksi.map((t) => [
            asShortDate(t.tanggal),
            t.tanggal.hour.toString().padLeft(2, '0'),
            t.total.toStringAsFixed(0),
            t.jenisTransaksi.label,
            t.metodeBayar?.label ?? '-',
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Export bulanan — one row per day.
  static String exportLaporanBulanan(
    LaporanSummary summary,
    String monthLabel,
  ) {
    // Build a map of date → daily totals and breakdown from chartPoints.
    final incomeMap = <String, _DailyRow>{};
    for (final p in summary.chartPoints) {
      final key = asShortDate(p.date);
      incomeMap[key] = _DailyRow(
        date: p.date,
        totalNominal: p.totalNominal,
        jumlahTransaksi: 0,
        nominalObat: 0,
        nominalPraktek: 0,
        nominalTunai: 0,
        nominalQris: 0,
      );
    }

    final rows = <List<dynamic>>[
      ['Tanggal', 'Total Nominal', 'Jumlah Transaksi', 'Obat', 'Praktek', 'Tunai', 'QRIS'],
      ...incomeMap.entries.map((e) => [
            e.key,
            e.value.totalNominal.toStringAsFixed(0),
            e.value.jumlahTransaksi.toString(),
            e.value.nominalObat.toStringAsFixed(0),
            e.value.nominalPraktek.toStringAsFixed(0),
            e.value.nominalTunai.toStringAsFixed(0),
            e.value.nominalQris.toStringAsFixed(0),
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  /// Export tahunan — one row per month.
  static String exportLaporanTahunan(
    LaporanSummary summary,
    String year,
  ) {
    final rows = <List<dynamic>>[
      ['Bulan', 'Total Nominal', 'Jumlah Transaksi', 'Obat', 'Praktek'],
      ...List.generate(12, (i) {
        final month = i + 1;
        // For yearly export, use the summary totals directly.
        // chartPoints covers the active period; map it to months.
        final monthPoints = summary.chartPoints
            .where((p) => p.date.month == month)
            .toList();
        final total = monthPoints.fold<double>(0, (s, p) => s + p.totalNominal);
        final count = monthPoints.length;
        // Approximate breakdown using the ratio from the full summary.
        final obatRatio = summary.jumlahTransaksiReadyStock /
            (summary.jumlahTransaksi > 0 ? summary.jumlahTransaksi : 1);
        final nominalObat = total * obatRatio;
        final nominalPraktek = total - nominalObat;
        return [
          '$year-${month.toString().padLeft(2, '0')}',
          total.toStringAsFixed(0),
          count.toString(),
          nominalObat.toStringAsFixed(0),
          nominalPraktek.toStringAsFixed(0),
        ];
      }),
    ];
    return const ListToCsvConverter().convert(rows);
  }
}

class _DailyRow {
  _DailyRow({
    required this.date,
    required this.totalNominal,
    required this.jumlahTransaksi,
    required this.nominalObat,
    required this.nominalPraktek,
    required this.nominalTunai,
    required this.nominalQris,
  });
  final DateTime date;
  final double totalNominal;
  final int jumlahTransaksi;
  final double nominalObat;
  final double nominalPraktek;
  final double nominalTunai;
  final double nominalQris;
}

String asShortDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
