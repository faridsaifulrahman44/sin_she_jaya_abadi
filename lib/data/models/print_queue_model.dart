/// Status print job dalam queue.
enum PrintQueueStatus {
  pending('pending', 'Menunggu'),
  printed('printed', 'Sudah Cetak'),
  failed('failed', 'Gagal');

  const PrintQueueStatus(this.value, this.label);
  final String value;
  final String label;

  static PrintQueueStatus fromString(String? value) {
    return PrintQueueStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PrintQueueStatus.pending,
    );
  }
}

/// Model untuk satu record print queue.
class PrintQueueModel {
  const PrintQueueModel({
    required this.id,
    required this.idTransaksi,
    required this.queueAt,
    required this.status,
    this.notes,
    // Optional join fields
    this.totalTransaksi,
    this.tanggalTransaksi,
    this.metodeBayarLabel,
  });

  final int id;
  final int idTransaksi;
  final DateTime queueAt;
  final PrintQueueStatus status;
  final String? notes;

  /// Joined from transaksi — total transaksi.
  final double? totalTransaksi;
  /// Joined from transaksi — tanggal transaksi.
  final DateTime? tanggalTransaksi;
  /// Joined label from transaksi metode_bayar.
  final String? metodeBayarLabel;

  String get formattedTotal =>
      totalTransaksi != null ? 'Rp${totalTransaksi!.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}' : '-';

  String get formattedQueueAt {
    final d = queueAt;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}