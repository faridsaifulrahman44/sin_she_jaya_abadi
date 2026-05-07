import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../models/obat_masuk_model.dart';
import 'base_repository.dart';

class ObatMasukRepository extends BaseRepository {
  ObatMasukRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;
  static const String _detailSelect =
      'id_masuk,id_obat,tanggal_masuk,jumlah_masuk,keterangan,id_admin,created_at,obat(nama_obat,foto_url)';

  Future<List<ObatMasukModel>> getObatMasuk({DateTime? tanggal}) {
    return guard(() async {
      final response = tanggal == null
          ? await _client
              .from(DbTables.obatMasuk)
              .select()
              .order('tanggal_masuk', ascending: false)
              .order('id_masuk', ascending: false)
          : await _client
              .from(DbTables.obatMasuk)
              .select()
              .eq('tanggal_masuk', formatDateDb(tanggal))
              .order('id_masuk', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatMasukModel.fromMap)
          .toList();
    });
  }

  Future<List<ObatMasukModel>> getObatMasukByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from(DbTables.obatMasuk)
          .select()
          .gte('tanggal_masuk', formatDateDb(startDate))
          .lte('tanggal_masuk', formatDateDb(endDate))
          .order('tanggal_masuk', ascending: false)
          .order('id_masuk', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatMasukModel.fromMap)
          .toList();
    });
  }

  Future<List<ObatMasukModel>> getObatMasukByObat(int idObat) {
    return guard(() async {
      final response = await _client
          .from(DbTables.obatMasuk)
          .select()
          .eq('id_obat', idObat)
          .order('tanggal_masuk', ascending: false)
          .order('id_masuk', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatMasukModel.fromMap)
          .toList();
    });
  }

  Future<List<ObatMasukModel>> getObatMasukDetailByTanggal(DateTime tanggal) {
    return guard(() async {
      final response = await _client
          .from(DbTables.obatMasuk)
          .select(_detailSelect)
          .eq('tanggal_masuk', formatDateDb(tanggal))
          .order('id_masuk', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatMasukModel.fromMap)
          .toList();
    });
  }

  Future<ObatMasukModel> insertObatMasuk({
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) {
    return guard(() async {
      final rpcResult = await _client.rpc(
        DbRpc.obatMasukInsertAtomic,
        params: {
          'p_id_obat': idObat,
          'p_tanggal_masuk': formatDateDb(tanggalMasuk),
          'p_jumlah_masuk': jumlahMasuk,
          'p_keterangan': parseNullableString(keterangan),
          'p_id_admin': idAdmin,
        },
      );

      final idMasuk = parseInt(rpcResult);
      if (idMasuk <= 0) {
        throw Exception('Gagal membuat transaksi obat masuk.');
      }

      final response = await _client
          .from(DbTables.obatMasuk)
          .select()
          .eq('id_masuk', idMasuk)
          .single();
      return ObatMasukModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<ObatMasukModel> updateObatMasuk({
    required int idMasuk,
    required int idObat,
    required DateTime tanggalMasuk,
    required int jumlahMasuk,
    required int idAdmin,
    String? keterangan,
  }) {
    return guard(() async {
      await _client.rpc(
        DbRpc.obatMasukUpdateAtomic,
        params: {
          'p_id_masuk': idMasuk,
          'p_id_obat': idObat,
          'p_tanggal_masuk': formatDateDb(tanggalMasuk),
          'p_jumlah_masuk': jumlahMasuk,
          'p_keterangan': parseNullableString(keterangan),
          'p_id_admin': idAdmin,
        },
      );

      final response = await _client
          .from(DbTables.obatMasuk)
          .select()
          .eq('id_masuk', idMasuk)
          .single();
      return ObatMasukModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<void> deleteObatMasuk(int idMasuk) {
    return guard(() async {
      await _client.rpc(
        DbRpc.obatMasukDeleteAtomic,
        params: {'p_id_masuk': idMasuk},
      );
    });
  }

  Future<void> deleteObatMasukByTanggal(DateTime tanggal) {
    return guard(() async {
      await _client.rpc(
        DbRpc.obatMasukDeleteByTanggalAtomic,
        params: {'p_tanggal_masuk': formatDateDb(tanggal)},
      );
    });
  }
}
