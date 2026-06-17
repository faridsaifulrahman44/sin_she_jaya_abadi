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

  /// Parse dari row Supabase `print_queue` (dengan optional join ke `transaksi`).
  /// Field null/undefined aman: numeric/date di-tryParse, status di-fallback ke pending.
  factory PrintQueueModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return PrintQueueModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      idTransaksi: (json['id_transaksi'] as num?)?.toInt() ?? 0,
      queueAt: parseDate(json['queue_at']),
      status: PrintQueueStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      // Optional join fields
      totalTransaksi: parseDouble(json['total_transaksi']),
      tanggalTransaksi: json['tanggal_transaksi'] != null
          ? DateTime.tryParse(json['tanggal_transaksi'].toString())
          : null,
      metodeBayarLabel: json['metode_bayar'] as String?,
    );
  }
}