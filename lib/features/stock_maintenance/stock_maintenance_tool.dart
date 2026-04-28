import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/parsers.dart';
import '../../data/repositories/base_repository.dart';
import '../../data/repositories/stock_recalculation_engine.dart';

/// Maintenance-only utilities untuk perbaikan data stok legacy.
///
/// Jangan dipakai di flow operasional harian.
/// Source of truth stok operasional tetap SQL/RPC atomic.
class StockMaintenanceTool extends BaseRepository {
  StockMaintenanceTool({SupabaseClient? client})
      : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Normalisasi baseline `stok_awal` untuk obat yang belum pernah sinkronisasi stok.
  ///
  /// Rumus:
  /// stok_awal = stok_saat_ini - total_masuk + total_keluar_non_legacy
  Future<StockNormalizationResult> normalizeStokAwalForNoOpname(int idObat) {
    return guard(() async {
      if (idObat <= 0) {
        return const StockNormalizationResult(
          idObat: 0,
          changed: false,
          reason: 'id_obat tidak valid',
        );
      }

      final opnameAny = await _client
          .from('sinkronisasi_stok')
          .select('id_opname')
          .eq('id_obat', idObat)
          .limit(1)
          .maybeSingle();
      if (opnameAny != null) {
        return StockNormalizationResult(
          idObat: idObat,
          changed: false,
          reason: 'dilewati: obat sudah punya histori sinkronisasi stok',
        );
      }

      final obat = await _client
          .from('obat')
          .select('stok_awal, stok_saat_ini')
          .eq('id_obat', idObat)
          .maybeSingle();
      if (obat == null) {
        return StockNormalizationResult(
          idObat: idObat,
          changed: false,
          reason: 'obat tidak ditemukan',
        );
      }

      final stokAwalNow = parseInt(obat['stok_awal'], fallback: 0);
      final stokSaatIni = parseInt(obat['stok_saat_ini'], fallback: 0);

      final masukRows = await _client
          .from('obat_masuk')
          .select('jumlah_masuk')
          .eq('id_obat', idObat);
      final totalMasuk = List<Map<String, dynamic>>.from(masukRows).fold<int>(
        0,
        (sum, row) => sum + parseInt(row['jumlah_masuk'], fallback: 0),
      );

      final keluarRows = await _client
          .from('obat_keluar_item')
          .select('jumlah')
          .eq('id_obat', idObat)
          .eq('is_legacy', false);
      final totalKeluar = List<Map<String, dynamic>>.from(keluarRows).fold<int>(
        0,
        (sum, row) => sum + parseInt(row['jumlah'], fallback: 0),
      );

      final normalized = StockRecalculationEngine.deriveInitialStock(
        stokSaatIni: stokSaatIni,
        totalMasuk: totalMasuk,
        totalKeluar: totalKeluar,
      );

      if (normalized == stokAwalNow) {
        return StockNormalizationResult(
          idObat: idObat,
          changed: false,
          previousStokAwal: stokAwalNow,
          normalizedStokAwal: normalized,
          reason: 'tidak berubah',
        );
      }

      await _client
          .from('obat')
          .update({'stok_awal': normalized}).eq('id_obat', idObat);

      return StockNormalizationResult(
        idObat: idObat,
        changed: true,
        previousStokAwal: stokAwalNow,
        normalizedStokAwal: normalized,
      );
    });
  }

  Future<List<StockNormalizationResult>> normalizeMany(List<int> ids) {
    return guard(() async {
      final results = <StockNormalizationResult>[];
      for (final id in ids) {
        final result = await normalizeStokAwalForNoOpname(id);
        results.add(result);
      }
      return results;
    });
  }
}

class StockNormalizationResult {
  const StockNormalizationResult({
    required this.idObat,
    required this.changed,
    this.previousStokAwal,
    this.normalizedStokAwal,
    this.reason,
  });

  final int idObat;
  final bool changed;
  final int? previousStokAwal;
  final int? normalizedStokAwal;
  final String? reason;
}
