import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/parsers.dart';
import '../models/pasien_model.dart';
import 'base_repository.dart';

class PasienRepository extends BaseRepository {
  PasienRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<List<PasienModel>> getPasien({String? keyword}) {
    return guard(() async {
      final search = parseString(keyword);
      final response = search.isEmpty
          ? await _client
              .from('pasien')
              .select()
              .order('id_pasien', ascending: false)
          : await _client
              .from('pasien')
              .select()
              .ilike('nama_pasien', '%$search%')
              .order('id_pasien', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(PasienModel.fromMap)
          .toList();
    });
  }

  Future<PasienModel?> getPasienById(int idPasien) {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .select()
          .eq('id_pasien', idPasien)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return PasienModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<List<PasienModel>> getPasienByTanggalJanjian(DateTime tanggal) {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .select()
          .eq('tanggal_janjian', formatDateDb(tanggal))
          .order('nama_pasien', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(PasienModel.fromMap)
          .toList();
    });
  }

  Future<List<PasienModel>> getPasienByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .select()
          .gte('tanggal_janjian', formatDateDb(startDate))
          .lte('tanggal_janjian', formatDateDb(endDate))
          .order('tanggal_janjian', ascending: false)
          .order('id_pasien', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(PasienModel.fromMap)
          .toList();
    });
  }

  Future<List<DateTime>> getTanggalJanjian() {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .select('tanggal_janjian')
          .not('tanggal_janjian', 'is', null)
          .order('tanggal_janjian', ascending: false);

      final seen = <String>{};
      final uniqueDates = <DateTime>[];

      for (final row in List<Map<String, dynamic>>.from(response)) {
        final rawDate = parseNullableDate(row['tanggal_janjian']);
        if (rawDate == null) {
          continue;
        }
        final key = formatDateDb(rawDate);
        if (seen.add(key)) {
          uniqueDates.add(rawDate);
        }
      }

      return uniqueDates;
    });
  }

  Future<PasienModel> insertPasien({
    required String nomorPasien,
    required String namaPasien,
    required String alamat,
    required int usia,
    required String jenisKelamin,
    required DateTime tanggalJanjian,
  }) {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .insert({
            'nomor_pasien': nomorPasien.trim(),
            'nama_pasien': namaPasien.trim(),
            'alamat': parseNullableString(alamat),
            'usia': usia,
            'jenis_kelamin': jenisKelamin,
            'tanggal_janjian': formatDateDb(tanggalJanjian),
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      return PasienModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<PasienModel> updatePasien({
    required int idPasien,
    required String nomorPasien,
    required String namaPasien,
    required String alamat,
    required int usia,
    required String jenisKelamin,
    required DateTime tanggalJanjian,
  }) {
    return guard(() async {
      final response = await _client
          .from('pasien')
          .update({
            // nomor_pasien tetap dipertahankan saat edit.
            'nama_pasien': namaPasien.trim(),
            'alamat': parseNullableString(alamat),
            'usia': usia,
            'jenis_kelamin': jenisKelamin,
            'tanggal_janjian': formatDateDb(tanggalJanjian),
          })
          .eq('id_pasien', idPasien)
          .select()
          .single();

      return PasienModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Mengambil nomor pasien berikutnya.
  ///
  /// Kontrak ini bergantung pada renumber saat delete:
  /// nomor_pasien selalu rapat 1..N, sehingga next = count + 1.
  Future<String> getNextNomorPasien() {
    return guard(() async {
      final response =
          await _client.from('pasien').select().count(CountOption.exact);
      return (response.count + 1).toString();
    });
  }

  /// Menghapus pasien dan otomatis merapikan ulang nomor_pasien 1..N.
  ///
  /// DEPENDENCY: RPC `fn_pasien_delete_and_renumber`.
  /// Migration `supabase/migration_fase13_pasien_renumber_after_delete.sql`
  /// wajib sudah di-apply di database Supabase.
  /// Disarankan lanjut apply
  /// `supabase/migration_fase15_pasien_contract_cleanup.sql`
  /// untuk membersihkan kontrak lama `fn_pasien_delete_if_unused`.
  Future<Map<String, dynamic>> deletePasien(int idPasien) {
    return guard(() async {
      if (idPasien <= 0) {
        throw const ValidationException('Data pasien tidak valid.');
      }

      try {
        final result = await _client.rpc(
          'fn_pasien_delete_and_renumber',
          params: {'p_id_pasien': idPasien},
        );

        final data = Map<String, dynamic>.from(result as Map<String, dynamic>);
        if (data['deleted'] != true) {
          throw Exception('Gagal menghapus pasien.');
        }
        return data;
      } on PostgrestException catch (e) {
        final functionNotFound = e.code == 'PGRST202' || e.code == '42883';
        if (functionNotFound) {
          throw const ValidationException(
            'Fitur hapus pasien belum tersedia. '
            'Jalankan migration supabase/migration_fase13_pasien_renumber_after_delete.sql '
            'lalu supabase/migration_fase15_pasien_contract_cleanup.sql '
            'ke database Supabase terlebih dahulu.',
            code: 'RPC_NOT_FOUND',
          );
        }
        rethrow;
      }
    });
  }
}
