import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/db_tables.dart';
import '../error/app_exception.dart';
import 'supabase_client_provider.dart';

class SchemaGuard {
  SchemaGuard({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<void> verifyCriticalContracts() async {
    await _assertColumnsExist(
      table: DbTables.transaksi,
      columns: const [
        DbColumns.idTransaksi,
        DbColumns.tanggal,
        DbColumns.jenisTransaksi,
        DbColumns.total,
        DbColumns.idAdmin,
      ],
    );
    await _assertColumnsExist(
      table: DbTables.pasien,
      columns: const [DbColumns.idPasien, DbColumns.namaPasien],
    );
  }

  Future<void> _assertColumnsExist({
    required String table,
    required List<String> columns,
  }) async {
    try {
      await _client.from(table).select(columns.join(',')).limit(1);
    } on PostgrestException catch (error) {
      throw DatabaseException(
        'Versi aplikasi tidak cocok dengan schema database terbaru. '
        'Silakan sinkronisasi aplikasi.',
        code: 'schema_mismatch',
        cause: error,
        debugMessage: 'table=$table columns=${columns.join(",")}',
      );
    }
  }
}
