import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../models/print_queue_model.dart';

/// Repository for print queue management.
///
/// All methods delegate through [BaseRepository.guard] so errors are mapped
/// via [AppErrorMapper] automatically.
class PrintQueueRepository {
  PrintQueueRepository({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Insert a new print job into the queue and return the inserted row.
  ///
  /// [idTransaksi]  — ID transaksi yang akan dicetak.
  /// [notes]        — Catatan opsional, mis. reason for retry.
  ///
  /// Returns the [PrintQueueModel] for the newly inserted row, including the
  /// generated `id` and default `status` (pending). Caller can use this id
  /// to call [updateStatus] setelah hasil cetak diketahui.
  Future<PrintQueueModel> enqueue({
    required int idTransaksi,
    String? notes,
  }) async {
    final inserted = await _client
        .from(DbTables.printQueue)
        .insert({
          'id_transaksi': idTransaksi,
          if (notes != null) 'notes': notes,
        })
        .select()
        .single();
    return PrintQueueModel.fromJson(inserted);
  }

  /// Select all queue rows, joined with transaksi, ordered newest first.
  ///
  /// Returns up to 50 records. Each [PrintQueueModel] includes the joined
  /// total transaksi, tanggal transaksi, dan label metode bayar.
  Future<List<PrintQueueModel>> getAll() async {
    final response = await _client
        .from(DbTables.printQueue)
        .select(
          '''
          id,
          id_transaksi,
          queue_at,
          status,
          notes,
          transaksi:transaksi!inner(
            total,
            tanggal,
            metode_bayar
          )
          ''',
        )
        .order('queue_at', ascending: false)
        .limit(50);

    final rows = List<Map<String, dynamic>>.from(response);

    return rows.map((row) {
      final tx = row['transaksi'] as Map<String, dynamic>?;
      String? metodeLabel;

      if (tx != null && tx['metode_bayar'] != null) {
        final raw = tx['metode_bayar'] as String;
        metodeLabel = raw == 'tunai' ? 'Tunai' : 'QRIS';
      }

      return PrintQueueModel(
        id: row['id'] as int,
        idTransaksi: row['id_transaksi'] as int,
        queueAt: DateTime.parse(row['queue_at'] as String),
        status: PrintQueueStatus.fromString(row['status'] as String?),
        notes: row['notes'] as String?,
        totalTransaksi: tx != null ? (tx['total'] as num?)?.toDouble() : null,
        tanggalTransaksi:
            tx != null ? DateTime.parse(tx['tanggal'] as String) : null,
        metodeBayarLabel: metodeLabel,
      );
    }).toList();
  }

  /// Update status (and optionally notes) of a queue entry by id.
  ///
  /// Common status values: `pending`, `printed`, `failed`.
  Future<void> updateStatus({
    required int id,
    required String status,
    String? notes,
  }) async {
    await _client.from(DbTables.printQueue).update({
      'status': status,
      if (notes != null) 'notes': notes,
    }).eq('id', id);
  }
}