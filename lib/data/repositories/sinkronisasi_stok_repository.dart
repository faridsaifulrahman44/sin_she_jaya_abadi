import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../models/sinkronisasi_stok_model.dart';
import 'base_repository.dart';

/// Repository untuk fitur Sinkronisasi Stok Obat.
///
/// Tabel Supabase: `sinkronisasi_stok`.
class SinkronisasiStokRepository extends BaseRepository {
  SinkronisasiStokRepository({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Nama tabel Supabase.
  static const tableName = DbTables.sinkronisasiStok;

  Future<List<SinkronisasiStokModel>> getSinkronisasiStok({DateTime? tanggal}) {
    return guard(() async {
      final response = tanggal == null
          ? await _client
              .from(tableName)
              .select()
              .order('tanggal_opname', ascending: false)
              .order('id_opname', ascending: false)
          : await _client
              .from(tableName)
              .select()
              .eq('tanggal_opname', formatDateDb(tanggal))
              .order('id_opname', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(SinkronisasiStokModel.fromMap)
          .toList();
    });
  }

  Future<List<SinkronisasiStokModel>> getSinkronisasiStokByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from(tableName)
          .select()
          .gte('tanggal_opname', formatDateDb(startDate))
          .lte('tanggal_opname', formatDateDb(endDate))
          .order('tanggal_opname', ascending: false)
          .order('id_opname', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(SinkronisasiStokModel.fromMap)
          .toList();
    });
  }

  Future<List<SinkronisasiStokModel>> getSinkronisasiStokByObat(int idObat) {
    return guard(() async {
      final response = await _client
          .from(tableName)
          .select()
          .eq('id_obat', idObat)
          .order('tanggal_opname', ascending: false)
          .order('id_opname', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(SinkronisasiStokModel.fromMap)
          .toList();
    });
  }

  /// Menyimpan entri sinkronisasi stok, lalu memicu recalculation stok obat.
  Future<SinkronisasiStokModel> insertSinkronisasiStok({
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) {
    return guard(() async {
      final rpcResult = await _client.rpc(
        DbRpc.stockOpnameInsertAtomic,
        params: {
          'p_id_obat': idObat,
          'p_tanggal_opname': formatDateDb(tanggalOpname),
          'p_stok_sistem': stokSistem,
          'p_stok_fisik': stokFisik,
          'p_alasan_penyesuaian': parseNullableString(alasanPenyesuaian),
          'p_id_admin': idAdmin,
        },
      );

      final idOpname = parseInt(rpcResult);
      if (idOpname <= 0) {
        throw Exception('Gagal menyimpan sinkronisasi stok.');
      }

      final response = await _client
          .from(tableName)
          .select()
          .eq('id_opname', idOpname)
          .single();
      return SinkronisasiStokModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Memperbarui entri sinkronisasi stok, lalu memicu recalculation stok obat.
  Future<SinkronisasiStokModel> updateSinkronisasiStok({
    required int idOpname,
    required int idObat,
    required DateTime tanggalOpname,
    required int stokSistem,
    required int stokFisik,
    required int idAdmin,
    String? alasanPenyesuaian,
  }) {
    return guard(() async {
      await _client.rpc(
        DbRpc.stockOpnameUpdateAtomic,
        params: {
          'p_id_opname': idOpname,
          'p_id_obat': idObat,
          'p_tanggal_opname': formatDateDb(tanggalOpname),
          'p_stok_sistem': stokSistem,
          'p_stok_fisik': stokFisik,
          'p_alasan_penyesuaian': parseNullableString(alasanPenyesuaian),
          'p_id_admin': idAdmin,
        },
      );

      final response = await _client
          .from(tableName)
          .select()
          .eq('id_opname', idOpname)
          .single();
      return SinkronisasiStokModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Menghapus entri sinkronisasi stok, stok dikembalikan ke nilai sebelumnya.
  Future<void> deleteSinkronisasiStok(int idOpname) {
    return guard(() async {
      await _client.rpc(
        DbRpc.stockOpnameDeleteAtomic,
        params: {'p_id_opname': idOpname},
      );
    });
  }

  Future<void> deleteSinkronisasiStokByTanggal(DateTime tanggalOpname) {
    return guard(() async {
      await _client.rpc(
        DbRpc.stockOpnameDeleteByTanggalAtomic,
        params: {'p_tanggal_opname': formatDateDb(tanggalOpname)},
      );
    });
  }
}
