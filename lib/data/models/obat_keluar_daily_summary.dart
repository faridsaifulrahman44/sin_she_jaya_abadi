/// Ringkasan harian transaksi obat keluar.
///
/// [jumlahItem] = jumlah unit/baris item pada tanggal tersebut.
/// [jumlahNota] = jumlah nota (header transaksi) pada tanggal tersebut.
class ObatKeluarDailySummary {
  const ObatKeluarDailySummary({
    required this.tanggal,
    required this.jumlahItem,
    required this.jumlahNota,
    required this.totalNominal,
  });

  final DateTime tanggal;

  /// Jumlah unit/baris item (qty) pada tanggal ini.
  final int jumlahItem;

  /// Jumlah nota (header transaksi) pada tanggal ini.
  final int jumlahNota;
  final double totalNominal;
}
