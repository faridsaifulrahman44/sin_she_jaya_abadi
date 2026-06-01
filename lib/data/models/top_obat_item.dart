import '../../features/laporan/laporan_summary.dart';

/// Item representing a top-selling drug for reports.
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
  final String rankType; // gold | silver | bronze | plain

  String get formattedNominal => 'Rp${(totalNominal / 1000).toStringAsFixed(1)}rb';
}

/// Extension on LaporanSummary to expose top obat data.
extension LaporanTopObatExtension on LaporanSummary {
  List<TopObatItem> get topObatList {
    final items = _topObatRaw;
    if (items.isEmpty) return [];

    return items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      String rankType;
      if (idx == 0) {
        rankType = 'gold';
      } else if (idx == 1) {
        rankType = 'silver';
      } else if (idx == 2) {
        rankType = 'bronze';
      } else {
        rankType = 'plain';
      }
      return TopObatItem(
        rank: idx + 1,
        namaObat: item['nama'] as String? ?? 'Unknown',
        jumlahTerjual: item['qty'] as int? ?? 0,
        totalNominal: (item['nominal'] as num?)?.toDouble() ?? 0,
        rankType: rankType,
      );
    }).toList();
  }

  List<Map<String, dynamic>> get _topObatRaw => const [];
}