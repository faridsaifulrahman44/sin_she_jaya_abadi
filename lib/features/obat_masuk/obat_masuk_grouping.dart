import '../../data/models/obat_masuk_daily_summary.dart';
import '../../data/models/obat_masuk_model.dart';

DateTime _normalizeDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

List<ObatMasukDailySummary> groupObatMasukByTanggal(
  List<ObatMasukModel> items,
) {
  final grouped = <DateTime, ObatMasukDailySummary>{};

  for (final item in items) {
    final key = _normalizeDate(item.tanggalMasuk);
    final current = grouped[key];
    grouped[key] = ObatMasukDailySummary(
      tanggal: key,
      jumlahItem: (current?.jumlahItem ?? 0) + 1,
      totalJumlahMasuk: (current?.totalJumlahMasuk ?? 0) + item.jumlahMasuk,
    );
  }

  return grouped.values.toList()
    ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
}
