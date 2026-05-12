import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../models/kehadiran_model.dart';
import 'base_repository.dart';

class KehadiranRepository extends BaseRepository {
  KehadiranRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<List<KehadiranModel>> getKehadiranByTanggal(DateTime tanggal) {
    return guard(() async {
      final response = await _client
          .from('kehadiran_pasien')
          .select()
          .eq('tanggal_hadir', formatDateDb(tanggal))
          .order('id_kehadiran', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KehadiranModel.fromMap)
          .toList();
    });
  }

  Future<List<KehadiranModel>> getKehadiranByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from('kehadiran_pasien')
          .select()
          .gte('tanggal_hadir', formatDateDb(startDate))
          .lte('tanggal_hadir', formatDateDb(endDate))
          .order('tanggal_hadir', ascending: false)
          .order('id_kehadiran', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KehadiranModel.fromMap)
          .toList();
    });
  }

  Future<List<KehadiranModel>> getKehadiranByPasien(int idPasien) {
    return guard(() async {
      final response = await _client
          .from('kehadiran_pasien')
          .select()
          .eq('id_pasien', idPasien)
          .order('tanggal_hadir', ascending: false)
          .order('id_kehadiran', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KehadiranModel.fromMap)
          .toList();
    });
  }

  Future<KehadiranModel?> getKehadiranByPasienDanTanggal({
    required int idPasien,
    required DateTime tanggal,
  }) {
    return guard(() async {
      final response = await _client
          .from('kehadiran_pasien')
          .select()
          .eq('id_pasien', idPasien)
          .eq('tanggal_hadir', formatDateDb(tanggal))
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return KehadiranModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<KehadiranModel> insertKehadiran({
    required int idPasien,
    required DateTime tanggalHadir,
    required String statusHadir,
    required int idAdmin,
    String? keterangan,
  }) {
    return guard(() async {
      final response = await _client
          .from('kehadiran_pasien')
          .insert({
            'id_pasien': idPasien,
            'tanggal_hadir': formatDateDb(tanggalHadir),
            'status_hadir': statusHadir,
            'keterangan': parseNullableString(keterangan),
            'id_admin': idAdmin,
          })
          .select()
          .single();

      return KehadiranModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<KehadiranModel> upsertKehadiran({
    required int idPasien,
    required DateTime tanggalHadir,
    required String statusHadir,
    required int idAdmin,
    String? keterangan,
  }) {
    return guard(() async {
      final existing = await getKehadiranByPasienDanTanggal(
        idPasien: idPasien,
        tanggal: tanggalHadir,
      );

      if (existing == null) {
        return insertKehadiran(
          idPasien: idPasien,
          tanggalHadir: tanggalHadir,
          statusHadir: statusHadir,
          idAdmin: idAdmin,
          keterangan: keterangan,
        );
      }

      final response = await _client
          .from('kehadiran_pasien')
          .update({
            'status_hadir': statusHadir,
            'keterangan': parseNullableString(keterangan),
            'id_admin': idAdmin,
          })
          .eq('id_kehadiran', existing.idKehadiran)
          .select()
          .single();

      return KehadiranModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<void> deleteKehadiran(int idKehadiran) {
    return guard(() async {
      await _client
          .from('kehadiran_pasien')
          .delete()
          .eq('id_kehadiran', idKehadiran);
    });
  }

  /// Jumlah total record jadwal hari ini (semua status).
  Future<int> getCountKehadiranByTanggal(DateTime tanggal) async {
    final all = await getKehadiranByTanggal(tanggal);
    return all.length;
  }

  /// Jumlah pasien hadir (status=hadir) hari ini.
  Future<int> getCountHadirByTanggal(DateTime tanggal) async {
    final all = await getKehadiranByTanggal(tanggal);
    return all.where((k) => k.statusHadir == StatusHadir.hadir).length;
  }
}
