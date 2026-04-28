import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../../features/obat_keluar/obat_keluar_atomic_payload_builder.dart';
import '../models/obat_keluar_item_model.dart';
import '../models/obat_keluar_model.dart';
import 'base_repository.dart';

/// Repository transaksi obat keluar.
///
/// Operasi write (insert/update/delete) diproses atomik di DB
/// melalui RPC supaya header, item, total, dan stok selalu konsisten.
class ObatKeluarRepository extends BaseRepository {
  ObatKeluarRepository({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<List<ObatKeluarModel>> getObatKeluar({DateTime? tanggal}) {
    return guard(() async {
      final response = tanggal == null
          ? await _client
              .from('obat_keluar')
              .select()
              .order('tanggal_terjual', ascending: false)
              .order('id_terjual', ascending: false)
          : await _client
              .from('obat_keluar')
              .select()
              .eq('tanggal_terjual', formatDateDb(tanggal))
              .order('id_terjual', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatKeluarModel.fromMap)
          .toList();
    });
  }

  Future<List<ObatKeluarModel>> getObatKeluarByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from('obat_keluar')
          .select()
          .gte('tanggal_terjual', formatDateDb(startDate))
          .lte('tanggal_terjual', formatDateDb(endDate))
          .order('tanggal_terjual', ascending: false)
          .order('id_terjual', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatKeluarModel.fromMap)
          .toList();
    });
  }

  Future<List<ObatKeluarItemModel>> getObatKeluarItems(int idTerjual) {
    return guard(() async {
      final response = await _client
          .from('obat_keluar_item')
          .select()
          .eq('id_terjual', idTerjual)
          .order('id_item', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatKeluarItemModel.fromMap)
          .toList();
    });
  }

  Future<ObatKeluarModel> getObatKeluarWithItems(int idTerjual) async {
    return guard(() async {
      final header = await _client
          .from('obat_keluar')
          .select()
          .eq('id_terjual', idTerjual)
          .maybeSingle();

      if (header == null) {
        throw Exception('Transaksi tidak ditemukan: $idTerjual');
      }

      final items = await getObatKeluarItems(idTerjual);
      return ObatKeluarModel.fromMap(Map<String, dynamic>.from(header))
          .copyWith(items: items);
    });
  }

  Future<ObatKeluarModel> insertObatKeluar({
    required DateTime tanggalTerjual,
    required List<ObatKeluarItemModel> items,
    String? keterangan,
    required int idAdmin,
    String? noEtalase,
  }) {
    return guard(() async {
      final payloadItems = ObatKeluarAtomicPayloadBuilder.build(items);

      final rpcResult = await _client.rpc(
        'fn_obat_keluar_insert_atomic',
        params: {
          'p_tanggal_terjual': formatDateDb(tanggalTerjual),
          'p_no_etalase': parseNullableString(noEtalase),
          'p_keterangan': parseNullableString(keterangan),
          'p_id_admin': idAdmin,
          'p_items': payloadItems,
        },
      );

      final idTerjual = parseInt(rpcResult);
      if (idTerjual <= 0) {
        throw Exception('Gagal membuat transaksi obat keluar.');
      }

      return getObatKeluarWithItems(idTerjual);
    });
  }

  Future<ObatKeluarModel> updateObatKeluar({
    required int idTerjual,
    required DateTime tanggalTerjual,
    required List<ObatKeluarItemModel> items,
    String? keterangan,
    required int idAdmin,
    String? noEtalase,
  }) {
    return guard(() async {
      final payloadItems = ObatKeluarAtomicPayloadBuilder.build(items);

      await _client.rpc(
        'fn_obat_keluar_update_atomic',
        params: {
          'p_id_terjual': idTerjual,
          'p_tanggal_terjual': formatDateDb(tanggalTerjual),
          'p_no_etalase': parseNullableString(noEtalase),
          'p_keterangan': parseNullableString(keterangan),
          'p_id_admin': idAdmin,
          'p_items': payloadItems,
        },
      );

      return getObatKeluarWithItems(idTerjual);
    });
  }

  Future<void> deleteObatKeluar(int idTerjual) {
    return guard(() async {
      await _client.rpc(
        'fn_obat_keluar_delete_atomic',
        params: {'p_id_terjual': idTerjual},
      );
    });
  }

  Future<void> deleteObatKeluarByTanggal(DateTime tanggal) {
    return guard(() async {
      await _client.rpc(
        'fn_obat_keluar_delete_by_tanggal_atomic',
        params: {'p_tanggal_terjual': formatDateDb(tanggal)},
      );
    });
  }
}
