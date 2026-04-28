/// Aggregated daily summary for ObatMasuk list page.
class ObatMasukDailySummary {
  const ObatMasukDailySummary({
    required this.tanggal,
    required this.jumlahItem,
    required this.totalJumlahMasuk,
  });

  final DateTime tanggal;
  final int jumlahItem;
  final int totalJumlahMasuk;
}
