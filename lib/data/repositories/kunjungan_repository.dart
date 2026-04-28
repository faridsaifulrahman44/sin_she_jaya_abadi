import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../models/kunjungan_model.dart';
import 'base_repository.dart';

class KunjunganRepository extends BaseRepository {
  KunjunganRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Ambil semua kunjungan untuk pasien tertentu (latest first).
  Future<List<KunjunganModel>> getKunjunganByPasien(int idPasien) {
    return guard(() async {
      final response = await _client
          .from('kunjungan_pasien')
          .select()
          .eq('id_pasien', idPasien)
          .order('tanggal_kunjungan', ascending: false)
          .order('id_kunjungan', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KunjunganModel.fromMap)
          .toList();
    });
  }

  /// Ambil kunjungan by ID.
  Future<KunjunganModel?> getKunjunganById(int idKunjungan) {
    return guard(() async {
      final response = await _client
          .from('kunjungan_pasien')
          .select()
          .eq('id_kunjungan', idKunjungan)
          .maybeSingle();

      if (response == null) return null;
      return KunjunganModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Insert kunjungan baru.
  Future<KunjunganModel> insertKunjungan({
    required int idPasien,
    required DateTime tanggalKunjungan,
    String? keluhanSingkat,
    String? catatanHasil,
    String? tindakLanjut,
    DateTime? tanggalKontrolBerikutnya,
    required int idAdmin,
  }) {
    return guard(() async {
      final response = await _client
          .from('kunjungan_pasien')
          .insert({
            'id_pasien': idPasien,
            'tanggal_kunjungan': formatDateDb(tanggalKunjungan),
            'keluhan_singkat': parseNullableString(keluhanSingkat),
            'catatan_hasil': parseNullableString(catatanHasil),
            'tindak_lanjut': parseNullableString(tindakLanjut),
            'tanggal_kontrol_berikutnya': tanggalKontrolBerikutnya == null
                ? null
                : formatDateDb(tanggalKontrolBerikutnya),
            'id_admin': idAdmin,
          })
          .select()
          .single();

      return KunjunganModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Update kunjungan.
  Future<KunjunganModel> updateKunjungan({
    required int idKunjungan,
    String? keluhanSingkat,
    String? catatanHasil,
    String? tindakLanjut,
    DateTime? tanggalKontrolBerikutnya,
  }) {
    return guard(() async {
      final updatePayload = <String, dynamic>{
        'keluhan_singkat': parseNullableString(keluhanSingkat),
        'catatan_hasil': parseNullableString(catatanHasil),
        'tindak_lanjut': parseNullableString(tindakLanjut),
        'tanggal_kontrol_berikutnya': tanggalKontrolBerikutnya == null
            ? null
            : formatDateDb(tanggalKontrolBerikutnya),
      };

      final response = await _client
          .from('kunjungan_pasien')
          .update(updatePayload)
          .eq('id_kunjungan', idKunjungan)
          .select()
          .single();

      return KunjunganModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Delete kunjungan.
  Future<void> deleteKunjungan(int idKunjungan) {
    return guard(() async {
      await _client
          .from('kunjungan_pasien')
          .delete()
          .eq('id_kunjungan', idKunjungan);
    });
  }

  /// Ambil tanggal kontrol berikutnya untuk beberapa pasien sekaligus.
  /// Map: idPasien → tanggal kontrol berikutnya (dari kunjungan terbaru
  /// yang punya jadwal kontrol).
  Future<Map<int, DateTime>> getKontrolBerikutnyaByPasienIds(
    List<int> idsPasien,
  ) async {
    if (idsPasien.isEmpty) return {};
    final map = <int, DateTime>{};

    // Fetch per-pasien: ambil 1 kunjungan terbaru yang punya kontrol.
    for (final idPasien in idsPasien) {
      if (map.containsKey(idPasien)) continue;

      final rows = await _client
          .from('kunjungan_pasien')
          .select('id_pasien, tanggal_kontrol_berikutnya')
          .eq('id_pasien', idPasien)
          .not('tanggal_kontrol_berikutnya', 'is', null)
          .order('tanggal_kunjungan', ascending: false)
          .limit(1);

      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isNotEmpty) {
        final tgl = parseNullableDate(list.first['tanggal_kontrol_berikutnya']);
        if (tgl != null) map[idPasien] = tgl;
      }
    }

    return map;
  }
}
