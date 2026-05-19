import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../models/kas_keluar_model.dart';
import 'base_repository.dart';

class KasKeluarRepository extends BaseRepository {
  KasKeluarRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<List<KasKeluarModel>> getAll() {
    return guard(() async {
      final response = await _client
          .from(DbTables.kasKeluar)
          .select()
          .order('tanggal', ascending: false)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KasKeluarModel.fromMap)
          .toList();
    });
  }

  Future<List<KasKeluarModel>> getByRange(DateTime start, DateTime end) {
    return guard(() async {
      final response = await _client
          .from(DbTables.kasKeluar)
          .select()
          .gte('tanggal', start.toIso8601String().split('T').first)
          .lte('tanggal', end.toIso8601String().split('T').first)
          .order('tanggal', ascending: false)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(KasKeluarModel.fromMap)
          .toList();
    });
  }

  Future<int> insert(KasKeluarModel model) {
    return guard(() async {
      final response = await _client
          .from(DbTables.kasKeluar)
          .insert(model.toInsertMap())
          .select('id')
          .single();
      return response['id'] as int;
    });
  }

  Future<void> delete(int id) {
    return guard(() async {
      await _client.from(DbTables.kasKeluar).delete().eq('id', id);
    });
  }
}