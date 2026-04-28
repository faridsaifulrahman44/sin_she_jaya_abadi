import '../../data/models/obat_keluar_daily_summary.dart';
import '../../data/models/obat_keluar_model.dart';

DateTime _normalizeDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Mengelompokkan transaksi obat keluar per tanggal.
///
/// [ObatKeluarDailySummary.jumlahItem] = jumlah unit/baris item per hari.
/// [ObatKeluarDailySummary.jumlahNota] = jumlah nota (header) per hari.
List<ObatKeluarDailySummary> groupObatKeluarByTanggal(
  List<ObatKeluarModel> items,
) {
  final grouped = <DateTime, _RunningTotal>{};

  for (final item in items) {
    final key = _normalizeDate(item.tanggalTerjual);
    final current = grouped[key];
    grouped[key] = _RunningTotal(
      jumlahItem: (current?.jumlahItem ?? 0) + item.displayJumlahItem,
      jumlahNota: (current?.jumlahNota ?? 0) + item.notaCount,
      totalNominal: (current?.totalNominal ?? 0) +
          (item.totalNominal ?? item.computedTotalNominal),
    );
  }

  final summaries = <ObatKeluarDailySummary>[];
  for (final entry in grouped.entries) {
    summaries.add(ObatKeluarDailySummary(
      tanggal: entry.key,
      jumlahItem: entry.value.jumlahItem,
      jumlahNota: entry.value.jumlahNota,
      totalNominal: entry.value.totalNominal,
    ));
  }

  summaries.sort((a, b) => b.tanggal.compareTo(a.tanggal));
  return summaries;
}

class _RunningTotal {
  const _RunningTotal({
    required this.jumlahItem,
    required this.jumlahNota,
    required this.totalNominal,
  });
  final int jumlahItem;
  final int jumlahNota;
  final double totalNominal;
}
