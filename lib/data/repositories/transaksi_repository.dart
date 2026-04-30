import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/formatters.dart';
import '../models/obat_model.dart';
import '../models/pasien_model.dart';
import '../models/transaksi_model.dart';
import 'base_repository.dart';

class TransaksiRepository extends BaseRepository {
  TransaksiRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;

  /// Ambil semua transaksi (latest first).
  Future<List<TransaksiModel>> getAllTransaksi() {
    return guard(() async {
      final response = await _client
          .from('transaksi')
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
          .from('transaksi')
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
          .from('transaksi')
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
          .from('transaksi_item')
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
          .from('transaksi')
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
          .from('transaksi_item')
          .select()
          .eq('id_transaksi', idTransaksi)
          .order('id_item', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map(TransaksiItemModel.fromMap)
          .toList();
    });
  }

  /// Insert transaksi baru dengan item (jika ready stock).
  /// Menggunakan RPC atomik `fn_transaksi_insert`.
  /// RPC ini menangani header, item, dan pengurangan stok dalam 1 transaksi DB.
  Future<TransaksiModel> insertTransaksi({
    required TransaksiModel transaksi,
    required List<TransaksiItemModel> items,
    required int idAdmin,
  }) async {
    return guard(() async {
      // Coba RPC atomik dulu (fn_transaksi_insert sudah termasuk
      // INSERT item dengan FK id_transaksi yang benar + pengurangan stok).
      try {
        final itemsJson = items
            .map((item) => {
                  'id_obat': item.idObat,
                  'jumlah': item.jumlah,
                  'harga_satuan': item.hargaSatuan,
                  'subtotal': item.subtotal,
                  'satuan_terjual': item.satuanTerjual,
                })
            .toList();

        final rpcResult = await _client.rpc('fn_transaksi_insert', params: {
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

        final row = rpcResult is List
            ? (rpcResult).first as Map<String, dynamic>
            : rpcResult as Map<String, dynamic>;

        return TransaksiModel.fromMap(Map<String, dynamic>.from(row));
      } on PostgrestException catch (error) {
        final fnNotFound = error.code == '42883' ||
            error.code == 'PGRST202' ||
            error.message
                .toLowerCase()
                .contains('fn_transaksi_insert does not exist');

        if (!fnNotFound) rethrow;

        throw DatabaseException(
          'RPC fn_transaksi_insert belum tersedia. '
          'Terapkan migration Supabase terbaru sebelum tambah transaksi.',
          code: 'fn_transaksi_insert_missing',
          cause: error,
          debugMessage:
              'PostgrestException code=${error.code} message=${error.message}',
        );
      }
    });
  }

  /// Ambil obat yang ready stock (etalase 1 atau 2).
  Future<List<ObatModel>> getObatReadyStock() {
    return guard(() async {
      // Ambil semua dan filter di memory (karena in_ tidak tersedia di versi ini)
      final response = await _client
          .from('obat')
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
          .from('pasien')
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
          .from('pasien')
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
          .from('admin')
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
}
