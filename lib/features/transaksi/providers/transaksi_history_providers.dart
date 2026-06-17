import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:klinik_mobile_app/core/auth/admin_session.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';

import '../repositories/transaksi_history_repository.dart';

class TransaksiHistoryQuery {
  const TransaksiHistoryQuery({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransaksiHistoryQuery &&
        startDate.year == other.startDate.year &&
        startDate.month == other.startDate.month &&
        startDate.day == other.startDate.day &&
        endDate.year == other.endDate.year &&
        endDate.month == other.endDate.month &&
        endDate.day == other.endDate.day;
  }

  @override
  int get hashCode {
    return Object.hash(
      startDate.year,
      startDate.month,
      startDate.day,
      endDate.year,
      endDate.month,
      endDate.day,
    );
  }
}

final transaksiHistoryRepositoryProvider =
    Provider<TransaksiHistoryRepository>((ref) {
  return SupabaseTransaksiHistoryRepository();
});

final adminRoleProvider = FutureProvider<AdminRole>((ref) async {
  return AdminSession.getRole();
});

final transaksiHistoryByRangeProvider =
    FutureProvider.family<List<TransaksiModel>, TransaksiHistoryQuery>(
  (ref, query) async {
    final repository = ref.watch(transaksiHistoryRepositoryProvider);
    return repository.getByDateRange(query.startDate, query.endDate);
  },
);

final pasienNameByIdProvider = FutureProvider.family<String, int>((ref, id) async {
  final repository = ref.watch(transaksiHistoryRepositoryProvider);
  final result = await repository.getNamaPasienById(id);
  return result == null || result.isEmpty ? 'Pasien #$id' : result;
});
