/// Reference-only stock replay engine.
///
/// Catatan penting:
/// - Bukan source of truth operasional aplikasi.
/// - Flow operasional stok memakai SQL/RPC atomic di database.
/// - Utility ini dipertahankan untuk test/unit reference legacy.
class StockMutation {
  const StockMutation._({
    required this.tanggal,
    required this.recordedAt,
    required this.priority,
    required this.sequence,
    required this.delta,
    required this.isReset,
  });

  factory StockMutation.masuk({
    required DateTime tanggal,
    required int jumlah,
    required int sequence,
    DateTime? recordedAt,
  }) {
    return StockMutation._(
      tanggal: tanggal,
      recordedAt: recordedAt,
      priority: 1,
      sequence: sequence,
      delta: jumlah < 0 ? 0 : jumlah,
      isReset: false,
    );
  }

  factory StockMutation.keluar({
    required DateTime tanggal,
    required int jumlah,
    required int sequence,
    DateTime? recordedAt,
  }) {
    return StockMutation._(
      tanggal: tanggal,
      recordedAt: recordedAt,
      priority: 2,
      sequence: sequence,
      delta: jumlah < 0 ? 0 : -jumlah,
      isReset: false,
    );
  }

  factory StockMutation.opname({
    required DateTime tanggal,
    required int stokFisik,
    required int sequence,
    DateTime? recordedAt,
  }) {
    return StockMutation._(
      tanggal: tanggal,
      recordedAt: recordedAt,
      priority: 3,
      sequence: sequence,
      delta: stokFisik < 0 ? 0 : stokFisik,
      isReset: true,
    );
  }

  final DateTime tanggal;
  final DateTime? recordedAt;
  final int priority;
  final int sequence;
  final int delta;
  final bool isReset;
}

class StockRecalculationEngine {
  const StockRecalculationEngine._();

  static int deriveInitialStock({
    required int stokSaatIni,
    required int totalMasuk,
    required int totalKeluar,
  }) {
    final value = stokSaatIni - totalMasuk + totalKeluar;
    return value < 0 ? 0 : value;
  }

  static int calculate({
    required int stokAwal,
    required List<StockMutation> mutations,
  }) {
    final sorted = [...mutations]..sort(_compareMutation);
    var current = stokAwal < 0 ? 0 : stokAwal;

    for (final mutation in sorted) {
      if (mutation.isReset) {
        current = mutation.delta;
      } else {
        current += mutation.delta;
      }

      if (current < 0) {
        current = 0;
      }
    }

    return current;
  }

  static int _compareMutation(StockMutation a, StockMutation b) {
    final dateA = DateTime(a.tanggal.year, a.tanggal.month, a.tanggal.day);
    final dateB = DateTime(b.tanggal.year, b.tanggal.month, b.tanggal.day);

    final byDate = dateA.compareTo(dateB);
    if (byDate != 0) return byDate;

    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) return byPriority;

    final timeA = a.recordedAt;
    final timeB = b.recordedAt;
    if (timeA != null && timeB != null) {
      final byTime = timeA.compareTo(timeB);
      if (byTime != 0) return byTime;
    } else if (timeA != null) {
      return 1;
    } else if (timeB != null) {
      return -1;
    }

    return a.sequence.compareTo(b.sequence);
  }
}
