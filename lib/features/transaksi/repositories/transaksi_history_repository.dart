import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:klinik_mobile_app/core/database/db_tables.dart';
import 'package:klinik_mobile_app/core/supabase/supabase_client_provider.dart';
import 'package:klinik_mobile_app/core/utils/formatters.dart';
import 'package:klinik_mobile_app/data/models/transaksi_model.dart';
import 'package:klinik_mobile_app/data/repositories/base_repository.dart';

import '../dto/transaksi_row_dto.dart';

abstract class TransaksiHistoryRepository {
  Future<List<TransaksiModel>> getByDateRange(DateTime start, DateTime end);
  Future<String?> getNamaPasienById(int idPasien);
}

class SupabaseTransaksiHistoryRepository extends BaseRepository
    implements TransaksiHistoryRepository {
  SupabaseTransaksiHistoryRepository({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  @override
  Future<List<TransaksiModel>> getByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksi)
          .select()
          .gte(DbColumns.tanggal, formatDateDb(start))
          .lte(DbColumns.tanggal, formatDateDb(end))
          .order(DbColumns.tanggal, ascending: false)
          .order(DbColumns.idTransaksi, ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiRowDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList();
    });
  }

  @override
  Future<String?> getNamaPasienById(int idPasien) {
    return guard(() async {
      final response = await _client
          .from(DbTables.pasien)
          .select(DbColumns.namaPasien)
          .eq(DbColumns.idPasien, idPasien)
          .maybeSingle();
      if (response == null) return null;
      return response[DbColumns.namaPasien] as String?;
    });
  }
}
