import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/db_tables.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../../features/transaksi/dto/create_transaction_payload_dto.dart';
import '../models/obat_model.dart';
import '../models/pasien_model.dart';
import '../models/top_obat_item.dart';
import '../models/transaksi_model.dart';
import 'base_repository.dart';
import 'obat_repository.dart';

class TransaksiRepository extends BaseRepository {
  TransaksiRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Ambil semua transaksi (latest first).
  Future<List<TransaksiModel>> getAllTransaksi() {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksi)
          .select()
          .order('tanggal', ascending: false)
          .order('id_transaksi', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiModel.fromMap)
          .toList();
    });
  }

  /// Ambil transaksi dalam rentang tanggal (inclusive), latest first.
  Future<List<TransaksiModel>> getTransaksiByRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksi)
          .select()
          .gte('tanggal', formatDateDb(startDate))
          .lte('tanggal', formatDateDb(endDate))
          .order('tanggal', ascending: false)
          .order('id_transaksi', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiModel.fromMap)
          .toList();
    });
  }

  /// Ambil transaksi yang terhubung ke pasien tertentu (id_pasien match).
  Future<List<TransaksiModel>> getTransaksiByPasien(int idPasien) {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksi)
          .select()
          .eq('id_pasien', idPasien)
          .order('tanggal', ascending: false)
          .order('id_transaksi', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiModel.fromMap)
          .toList();
    });
  }

  /// Ambil seluruh item transaksi (untuk agregasi laporan lintas transaksi).
  Future<List<TransaksiItemModel>> getAllTransaksiItems() {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksiItem)
          .select()
          .order('id_item', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiItemModel.fromMap)
          .toList();
    });
  }

  /// Ambil transaksi by ID.
  Future<TransaksiModel?> getTransaksiById(int idTransaksi) async {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksi)
          .select()
          .eq('id_transaksi', idTransaksi)
          .maybeSingle();

      if (response == null) return null;

      return TransaksiModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Ambil item-item transaksi ready stock.
  Future<List<TransaksiItemModel>> getTransaksiItems(int idTransaksi) {
    return guard(() async {
      final response = await _client
          .from(DbTables.transaksiItem)
          .select()
          .eq('id_transaksi', idTransaksi)
          .order('id_item', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiItemModel.fromMap)
          .toList();
    });
  }

  /// Insert transaksi baru dengan item (jika ready stock).
  /// Menggunakan RPC atomik `fn_create_transaction`.
  /// RPC ini menangani header, item, dan pengurangan stok dalam 1 transaksi DB.
  Future<TransaksiModel> insertTransaksi({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) {
    return createTransactionAtomic(
      transaksi: transaksi,
      items: items,
      idAdmin: idAdmin,
    );
  }

  /// Canonical path transaksi atomik.
  /// Fallback ke RPC lama (`fn_transaksi_insert`) jika environment belum apply
  /// migration terbaru.
  Future<TransaksiModel> createTransactionAtomic({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) async {
    return guard(() async {
      final itemsJson = _buildItemsPayload(items);

      try {
        final rpcResult =
            await _client.rpc(DbRpc.createTransactionAtomic, params: {
          'p_tanggal': transaksi.tanggal.toIso8601String().split('T').first,
          'p_jenis_transaksi': transaksi.jenisTransaksi.value,
          'p_total': transaksi.total,
          'p_metode_bayar': transaksi.metodeBayar?.value,
          'p_id_pasien': transaksi.idPasien,
          'p_keterangan': transaksi.keterangan,
          'p_durasi_harian': transaksi.durasiHarian,
          'p_id_admin': idAdmin,
          'p_items': itemsJson,
        });

        return _parseRpcTransaksiRow(rpcResult);
      } on PostgrestException catch (error) {
        if (!_isFunctionMissing(error, DbRpc.createTransactionAtomic)) rethrow;

        final legacyResult = await _client.rpc(DbRpc.transaksiInsertAtomic,
            params: {
              'p_tanggal': transaksi.tanggal.toIso8601String().split('T').first,
              'p_jenis_transaksi': transaksi.jenisTransaksi.value,
              'p_total': transaksi.total,
              'p_metode_bayar': transaksi.metodeBayar?.value,
              'p_id_pasien': transaksi.idPasien,
              'p_keterangan': transaksi.keterangan,
              'p_durasi_harian': transaksi.durasiHarian,
              'p_id_admin': idAdmin,
              'p_items': itemsJson,
            });
        return _parseRpcTransaksiRow(legacyResult);
      }
    });
  }

  bool _isFunctionMissing(PostgrestException error, String functionName) {
    final message = error.message.toLowerCase();
    return error.code == '42883' ||
        error.code == 'PGRST202' ||
        message.contains('$functionName does not exist');
  }

  List<Map<String, dynamic>> _buildItemsPayload(List<TransaksiItemModel> items) {
    return items
        .map(CreateTransactionItemDto.fromDomain)
        .map((dto) => dto.toMap())
        .toList(growable: false);
  }

  TransaksiModel _parseRpcTransaksiRow(dynamic rpcResult) {
    final row = rpcResult is List
        ? (rpcResult).first as Map<String, dynamic>
        : rpcResult as Map<String, dynamic>;
    return TransaksiModel.fromMap(Map<String, dynamic>.from(row));
  }

  /// Ambil obat yang ready stock (etalase 1 atau 2).
  Future<List<ObatModel>> getObatReadyStock() {
    return guard(() async {
      // Ambil semua dan filter di memory (karena in_ tidak tersedia di versi ini)
      final response = await _client
          .from(DbTables.obat)
          .select()
          .order('nama_obat', ascending: true);

      final allObat = List<Map<String, dynamic>>.from(response)
          .map(ObatModel.fromMap)
          .toList();

      // Filter etalase 1 dan 2
      return allObat
          .where((o) =>
              o.etalase.value == 'etalase1' || o.etalase.value == 'etalase2')
          .toList();
    });
  }

  /// Ambil semua pasien untuk dropdown.
  Future<List<PasienModel>> getAllPasien() {
    return guard(() async {
      final response = await _client
          .from(DbTables.pasien)
          .select()
          .order('nama_pasien', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(PasienModel.fromMap)
          .toList();
    });
  }

  /// Ambil pasien by ID.
  Future<String?> getNamaPasienById(int idPasien) async {
    return guard(() async {
      final response = await _client
          .from(DbTables.pasien)
          .select('nama_pasien')
          .eq('id_pasien', idPasien)
          .maybeSingle();

      if (response == null) return null;
      return response['nama_pasien'] as String?;
    });
  }

  /// Ambil admin name by ID.
  Future<String?> getNamaAdminById(int idAdmin) async {
    return guard(() async {
      final response = await _client
          .from(DbTables.admin)
          .select('nama_admin')
          .eq('id_admin', idAdmin)
          .maybeSingle();

      if (response == null) return null;
      return response['nama_admin'] as String?;
    });
  }

  /// Hitung total transaksi per periode.
  Future<double> getTotalTransaksiByRange(DateTime start, DateTime end) async {
    final data = await getAllTransaksi();
    final filtered = data
        .where((t) =>
            t.tanggal.isAfter(start.subtract(const Duration(days: 1))) &&
            t.tanggal.isBefore(end.add(const Duration(days: 1))))
        .toList();
    double total = 0.0;
    for (final t in filtered) {
      total += t.total;
    }
    return total;
  }

  /// Hitung jumlah transaksi per periode.
  Future<int> getCountTransaksiByRange(DateTime start, DateTime end) async {
    final data = await getAllTransaksi();
    return data
        .where((t) =>
            t.tanggal.isAfter(start.subtract(const Duration(days: 1))) &&
            t.tanggal.isBefore(end.add(const Duration(days: 1))))
        .length;
  }

  /// Total nominal transaksi hari ini (owner dashboard).
  Future<double> getTotalTransaksiHariIni(DateTime hariIni) {
    final start = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final end = start.add(const Duration(days: 1));
    return getTotalTransaksiByRange(start, end);
  }

  /// Total nominal transaksi obat Ready Stock hari ini.
  Future<double> getTotalObatHariIni(DateTime hariIni) async {
    final start = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final end = start.add(const Duration(days: 1));
    final allItems = await getAllTransaksiItems();
    // Filter items that belong to transaksi obat hari ini
    final allTransaksi = await getAllTransaksi();
    final todayTxIds = allTransaksi
        .where((t) =>
            !t.tanggal.isBefore(start) && t.tanggal.isBefore(end) &&
            t.jenisTransaksi.value == 'obatReadyStock')
        .map((t) => t.idTransaksi)
        .toSet();
    double total = 0.0;
    for (final item in allItems) {
      if (todayTxIds.contains(item.idTransaksi)) {
        total += item.subtotal;
      }
    }
    return total;
  }

  /// Jumlah transaksi hari ini (admin dashboard).
  Future<int> getCountTransaksiHariIni(DateTime hariIni) {
    final start = DateTime(hariIni.year, hariIni.month, hariIni.day);
    final end = start.add(const Duration(days: 1));
    return getCountTransaksiByRange(start, end);
  }

  /// Ambil top N obat yang paling banyak terjual dalam [days] hari terakhir.
  ///
  /// READ-ONLY — aman tanpa izin DB tambahan.
  /// Hanya menghitung item dari transaksi yang completed (tanggal <= hari ini)
  /// dan exclude transaksi Praktek (yang tidak punya id_obat).
  ///
  /// Return list diurutkan descending by [TopObatItem.jumlahTerjual].
  /// Jika [obatLookup] diberikan, dipakai untuk resolve foto key/url.
  Future<List<TopObatItem>> getTopObatByPeriod({
    int days = 7,
    int limit = 5,
    List<ObatModel>? obatLookup,
  }) async {
    final allItems = await getAllTransaksiItems();
    if (allItems.isEmpty) return const [];

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final allTx = await getAllTransaksi();
    final txById = {for (final t in allTx) t.idTransaksi: t};

    // Index obat by id — supplied or fetched
    final Map<int, ObatModel> obatById;
    if (obatLookup != null) {
      obatById = {for (final o in obatLookup) o.idObat: o};
    } else {
      // Lazy fetch via raw query — ringan karena tabel obat kecil
      final obatRepo = ObatRepository(client: _client);
      final listObat = await obatRepo.getObat();
      obatById = {for (final o in listObat) o.idObat: o};
    }

    final grouped = <int, _TopObatAccumulator>{};
    for (final item in allItems) {
      final tx = txById[item.idObat == 0 ? 0 : item.idTransaksi];
      if (tx == null) continue;
      if (tx.tanggal.isBefore(cutoff)) continue;
      if (item.jumlah <= 0) continue;

      final existing = grouped[item.idObat];
      if (existing != null) {
        grouped[item.idObat] = _TopObatAccumulator(
          namaObat: existing.namaObat,
          fotoKey: existing.fotoKey,
          fotoUpdatedAt: existing.fotoUpdatedAt,
          fotoUrl: existing.fotoUrl,
          jumlahTerjual: existing.jumlahTerjual + item.jumlah,
          totalNominal: existing.totalNominal + item.subtotal,
        );
      } else {
        final obat = obatById[item.idObat];
        grouped[item.idObat] = _TopObatAccumulator(
          namaObat: item.namaObat ?? obat?.namaObat ?? 'Obat #${item.idObat}',
          fotoKey: obat?.fotoKey,
          fotoUpdatedAt: obat?.fotoUpdatedAt,
          fotoUrl: obat?.fotoUrl,
          jumlahTerjual: item.jumlah,
          totalNominal: item.subtotal,
        );
      }
    }

    final sorted = grouped.values.toList()
      ..sort((a, b) => b.jumlahTerjual.compareTo(a.jumlahTerjual));

    return sorted.take(limit).toList().asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final rankType = idx == 0
          ? 'gold'
          : idx == 1
              ? 'silver'
              : idx == 2
                  ? 'bronze'
                  : 'plain';
      return TopObatItem(
        rank: idx + 1,
        namaObat: item.namaObat,
        jumlahTerjual: item.jumlahTerjual,
        totalNominal: item.totalNominal,
        rankType: rankType,
        // Foto context — dipakai TopObatTile untuk render thumbnail
        fotoKey: item.fotoKey,
        fotoUpdatedAt: item.fotoUpdatedAt,
        fotoUrl: item.fotoUrl,
      );
    }).toList();
  }

  /// Ambil total penjualan per hari untuk [days] hari terakhir.
  /// READ-ONLY. Return map keyed by DateTime (midnight), value = total nominal.
  /// Hari tanpa transaksi tetap ada di map dengan value 0.
  Future<Map<DateTime, double>> getDailySalesByRange(int days) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1));
    final end = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));

    final allTx = await getAllTransaksi();
    final result = <DateTime, double>{};

    // Seed semua hari dengan 0
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      result[DateTime(d.year, d.month, d.day)] = 0.0;
    }

    for (final t in allTx) {
      if (t.tanggal.isBefore(start) || !t.tanggal.isBefore(end)) continue;
      final key = DateTime(t.tanggal.year, t.tanggal.month, t.tanggal.day);
      result[key] = (result[key] ?? 0) + t.total;
    }

    return result;
  }
}

/// Internal accumulator untuk getTopObatByPeriod — tidak di-expose.
class _TopObatAccumulator {
  _TopObatAccumulator({
    required this.namaObat,
    this.fotoKey,
    this.fotoUpdatedAt,
    this.fotoUrl,
    required this.jumlahTerjual,
    required this.totalNominal,
  });
  final String namaObat;
  final String? fotoKey;
  final DateTime? fotoUpdatedAt;
  final String? fotoUrl;
  final int jumlahTerjual;
  final double totalNominal;
}
