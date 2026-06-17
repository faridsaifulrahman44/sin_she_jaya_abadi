import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../models/stock_movement_model.dart';
import 'base_repository.dart';

class StockMovementRepository extends BaseRepository {
  StockMovementRepository({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  Future<List<StockMovementModel>> getByObat(int idObat, {int limit = 200}) {
    return guard(() async {
      final response = await _client
          .from(DbTables.stockMovements)
          .select()
          .eq('id_obat', idObat)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response)
          .map(StockMovementModel.fromMap)
          .toList(growable: false);
    });
  }
}
