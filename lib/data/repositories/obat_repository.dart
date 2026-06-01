import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import '../../core/supabase/supabase_client_provider.dart';
import '../../core/utils/parsers.dart';
import '../models/obat_etalase.dart';
import '../models/obat_model.dart';
import '../models/obat_usage_info.dart';
import 'base_repository.dart';

class ObatRepository extends BaseRepository {
  ObatRepository({SupabaseClient? client}) : _client = client ?? SB.client;

  final SupabaseClient _client;
  static const String _fotoBucket = 'obat-images';
  static const int _maxFotoSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> _allowedFotoExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  Future<List<ObatModel>> getObat({String? keyword}) {
    return guard(() async {
      final search = parseString(keyword);
      final response = search.isEmpty
          ? await _client
              .from('obat')
              .select()
              .order('id_obat', ascending: false)
          : await _client
              .from('obat')
              .select()
              .ilike('nama_obat', '%$search%')
              .order('id_obat', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map(ObatModel.fromMap)
          .toList();
    });
  }

  /// Returns medicines where stok_saat_ini <= stok_minimum (low stock alert).
  Future<List<ObatModel>> getStokMenipis({int limit = 10}) {
    return guard(() async {
      // Fetch all and filter in-memory since Supabase PostgREST
      // does not support row-level comparisons between columns in a single filter.
      final all = await _client
          .from('obat')
          .select()
          .order('stok_saat_ini', ascending: true)
          .limit(limit * 3); // over-fetch for filtering

      final items = List<Map<String, dynamic>>.from(all)
          .map(ObatModel.fromMap)
          .where((m) => m.isLowStock)
          .take(limit)
          .toList();

      return items;
    });
  }

  /// Alias for getStokMenipis. Returns medicines where stok <= minimum threshold.
  Future<List<ObatModel>> getLowStock({int limit = 10}) =>
      getStokMenipis(limit: limit);

  /// Ambil obat yang DISPLAY saja (etalase 1 & 2 = Obat tab, etalase 3 = Praktek tab).
  /// Parameter [etalases] = null berarti tampilkan semua.
  /// Digunakan di TransaksiFormPage untuk memfilter berdasarkan tab aktif.
  Future<List<ObatModel>> getObatsByEtalase({List<Etalase>? etalases}) {
    return guard(() async {
      final response = await _client
          .from('obat')
          .select()
          .order('nama_obat', ascending: true);

      final allObat = List<Map<String, dynamic>>.from(response)
          .map(ObatModel.fromMap)
          .toList();

      if (etalases == null || etalases.isEmpty) {
        return allObat;
      }

      return allObat.where((o) => etalases.contains(o.etalase)).toList();
    });
  }

  /// Meminta DB menghitung ulang stok untuk 1 obat.
  ///
  /// Source of truth stok ada di SQL function:
  /// `fn_recalculate_obat_stok_single`.
  Future<void> recalculateStok(int idObat) {
    return guard(() async {
      if (idObat <= 0) {
        return;
      }

      await _client.rpc(
        'fn_recalculate_obat_stok_single',
        params: {'p_id_obat': idObat},
      );
    });
  }

  /// Recalculate stok untuk seluruh obat.
  Future<void> recalculateAllStok() {
    return guard(() async {
      final response = await _client.from('obat').select('id_obat');
      final ids = List<Map<String, dynamic>>.from(response)
          .map((row) => parseInt(row['id_obat']))
          .where((id) => id > 0)
          .toList();

      if (ids.isEmpty) {
        return;
      }

      await _client.rpc(
        'fn_recalculate_obat_stok_bulk',
        params: {'p_ids': ids},
      );
    });
  }

  Future<ObatModel> insertObat({
    required String namaObat,
    required int stokSaatIni,
    required int stokMinimum,
    required Etalase etalase,
    String? satuan,
    String? keterangan,
    String? fotoUrl,
    // ── Harga Source of Truth (FASE 1) ────────────────────────────────────
    num? hargaJual,
    String? satuanJual,
    bool? bisaEcer,
    num? hargaEcer,
    String? satuanEcer,
  }) {
    return guard(() async {
      final clampedStokAwal = stokSaatIni < 0 ? 0 : stokSaatIni;
      final response = await _client
          .from('obat')
          .insert({
            'nama_obat': namaObat.trim(),
            'stok_awal': clampedStokAwal,
            'stok_saat_ini': clampedStokAwal,
            'stok_minimum': stokMinimum,
            'etalase': etalase.value,
            'satuan': parseNullableString(satuan),
            'keterangan': parseNullableString(keterangan),
            'foto_url': parseNullableString(fotoUrl),
            // ── Harga ────────────────────────────────────────────────────────
            'harga_jual': hargaJual,
            'satuan_jual': parseNullableString(satuanJual),
            'bisa_ecer': bisaEcer ?? false,
            'harga_ecer': hargaEcer,
            'satuan_ecer': parseNullableString(satuanEcer),
          })
          .select()
          .single();

      return ObatModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<ObatModel> updateObat({
    required int idObat,
    required String namaObat,
    required int stokMinimum,
    required Etalase etalase,
    String? satuan,
    String? keterangan,
    String? fotoUrl,
    // ── Harga Source of Truth (FASE 1) ────────────────────────────────────
    num? hargaJual,
    String? satuanJual,
    bool? bisaEcer,
    num? hargaEcer,
    String? satuanEcer,
  }) {
    return guard(() async {
      final response = await _client
          .from('obat')
          .update({
            'nama_obat': namaObat.trim(),
            'stok_minimum': stokMinimum,
            'etalase': etalase.value,
            'satuan': parseNullableString(satuan),
            'keterangan': parseNullableString(keterangan),
            if (fotoUrl != null) 'foto_url': parseNullableString(fotoUrl),
            // ── Harga ──────────────────────────────────────────────────────
            'harga_jual': hargaJual,
            'satuan_jual': parseNullableString(satuanJual),
            'bisa_ecer': bisaEcer ?? false,
            'harga_ecer': hargaEcer,
            'satuan_ecer': parseNullableString(satuanEcer),
          })
          .eq('id_obat', idObat)
          .select()
          .single();

      return ObatModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  Future<ObatUsageInfo> checkObatUsage(int idObat) {
    return guard(() async {
      if (idObat <= 0) {
        return const ObatUsageInfo(
          usedInObatMasuk: false,
          usedInObatKeluarItem: false,
          usedInSinkronisasiStok: false,
        );
      }

      final usedInObatMasuk = await _existsUsage(
        table: 'obat_masuk',
        idColumn: 'id_masuk',
        idObat: idObat,
      );
      final usedInObatKeluarItem = await _existsUsage(
        table: 'obat_keluar_item',
        idColumn: 'id_item',
        idObat: idObat,
      );
      final usedInSinkronisasiStok = await _existsUsage(
        table: 'stock_opname',
        idColumn: 'id_opname',
        idObat: idObat,
      );

      return ObatUsageInfo(
        usedInObatMasuk: usedInObatMasuk,
        usedInObatKeluarItem: usedInObatKeluarItem,
        usedInSinkronisasiStok: usedInSinkronisasiStok,
      );
    });
  }

  Future<void> deleteObat(int idObat) {
    return guard(() async {
      if (idObat <= 0) {
        throw const ValidationException('Data obat tidak valid.');
      }

      String? fotoUrlBeforeDelete;
      try {
        fotoUrlBeforeDelete = await getFotoObat(idObat);
      } catch (_) {
        // Best effort only; jangan blokir flow hapus obat.
      }

      try {
        final rpcResult = await _client.rpc(
          'fn_obat_delete_if_unused',
          params: {'p_id_obat': idObat},
        );

        final payload = rpcResult is Map
            ? Map<String, dynamic>.from(rpcResult)
            : <String, dynamic>{};

        final deleted = _parseBool(payload['deleted']);
        if (deleted) {
          await _removeFotoObjectIfExists(
            fotoUrlBeforeDelete,
            swallowErrors: true,
          );
          return;
        }

        final usage = ObatUsageInfo.fromMap(payload);
        throw ValidationException(
          usage.toDeleteBlockedMessage(),
          code: 'obat_still_referenced',
        );
      } on PostgrestException catch (error) {
        final functionNotFound = error.code == '42883' ||
            error.code == 'PGRST202' ||
            error.message.toLowerCase().contains('fn_obat_delete_if_unused');
        if (functionNotFound) {
          throw const ValidationException(
            'Fitur hapus obat belum tersedia di database. '
            'Pastikan migration/RPC terbaru sudah di-apply.',
            code: 'RPC_NOT_FOUND',
          );
        }
        rethrow;
      }
    });
  }

  Future<bool> _existsUsage({
    required String table,
    required String idColumn,
    required int idObat,
  }) async {
    final row = await _client
        .from(table)
        .select(idColumn)
        .eq('id_obat', idObat)
        .limit(1)
        .maybeSingle();
    return row != null;
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return false;

    final raw = value.toString().trim().toLowerCase();
    return raw == 'true' || raw == '1' || raw == 't' || raw == 'yes';
  }

  /// Upload foto obat ke Supabase Storage lalu simpan ke tabel obat.
  ///
  /// Menulis ke kolom: `foto_key` + `foto_updated_at` (source of truth).
  /// Fallback: `foto_url` untuk backward compatibility data lama.
  ///
  /// Jika [etalase] dan [namaObat] supplied, pathStorage di-generate
  /// sebagai `etalase-value/nama_obat_snake_case.webp`.
  /// Jika tidak supplied, fallback ke format lama `obat/{idObat}/{timestamp}.{ext}`.
  Future<String> uploadFotoObat({
    required int idObat,
    required Uint8List bytes,
    required String fileName,
    String? previousFotoUrl,
    // ── Foto Source of Truth (FASE 2) ─────────────────────────────────────
    Etalase? etalase,
    String? namaObat,
  }) {
    return guard(() async {
      if (idObat <= 0) {
        throw const ValidationException('Data obat tidak valid.');
      }
      if (bytes.isEmpty) {
        throw const ValidationException('File gambar kosong.');
      }
      if (bytes.length > _maxFotoSizeBytes) {
        throw const ValidationException(
          'Ukuran foto maksimal 5 MB. '
          'Pilih gambar yang lebih kecil.',
          code: 'foto_too_large',
        );
      }

      var extension = _extractFileExtension(fileName);
      if (extension == null || !_allowedFotoExtensions.contains(extension)) {
        extension = _detectImageExtensionFromBytes(bytes);
      }
      if (extension == null || !_allowedFotoExtensions.contains(extension)) {
        throw const ValidationException(
          'Format foto tidak didukung. Gunakan JPG, PNG, atau WEBP.',
          code: 'foto_invalid_type',
        );
      }

      // ── Build object path (FASE 2: etalase-format, fallback legacy) ──────
      final objectPath = _buildUploadObjectPath(
        idObat: idObat,
        extension: extension,
        etalase: etalase,
        namaObat: namaObat,
      );

      try {
        await _client.storage.from(_fotoBucket).uploadBinary(
              objectPath,
              bytes,
              fileOptions: FileOptions(
                contentType: _contentTypeForExtension(extension),
                cacheControl: '31536000',
                upsert: false,
              ),
            );
      } on StorageException catch (error) {
        throw ValidationException(
          _mapStorageUploadError(error),
          code: error.statusCode,
          cause: error,
          debugMessage: error.toString(),
        );
      }

      final fotoUpdatedAt = DateTime.now().toUtc();

      // ── Write to foto_key + foto_updated_at (source of truth FASE 2) ─────
      await _client.from('obat').update({
        'foto_key': objectPath,
        'foto_updated_at': fotoUpdatedAt.toIso8601String(),
      }).eq('id_obat', idObat);

      // Legacy: juga tulis foto_url agar data lama tetap bisa resolve
      final publicUrl = _client.storage.from(_fotoBucket).getPublicUrl(objectPath);

      final oldPath = _extractStoragePathFromFotoUrl(previousFotoUrl);
      if (oldPath != null && oldPath != objectPath) {
        await _removeFotoObjectIfExists(previousFotoUrl, swallowErrors: true);
      }

      return publicUrl;
    });
  }

  /// Update foto URL secara manual.
  Future<void> updateFotoUrl(int idObat, String? fotoUrl) {
    return guard(() async {
      await _client
          .from('obat')
          .update({'foto_url': fotoUrl}).eq('id_obat', idObat);
    });
  }

  /// Update hanya kolom `foto_key` + `foto_updated_at` untuk 1 row obat.
  ///
  /// Dipakai oleh [FotoObatUploadService] setelah upload Storage sukses.
  /// Tidak menyentuh kolom lain — minimal update untuk cache busting.
  Future<ObatModel> updateFotoKey({
    required int idObat,
    required String fotoKey,
  }) {
    return guard(() async {
      if (idObat <= 0) {
        throw const ValidationException('Data obat tidak valid.');
      }
      final response = await _client
          .from('obat')
          .update({
            'foto_key': fotoKey,
            'foto_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id_obat', idObat)
          .select()
          .single();
      return ObatModel.fromMap(Map<String, dynamic>.from(response));
    });
  }

  /// Hapus foto produk obat.
  Future<void> deleteFotoObat(
    int idObat, {
    String? fotoUrl,
  }) {
    return guard(() async {
      String? currentFotoUrl = parseNullableString(fotoUrl);
      currentFotoUrl ??= await getFotoObat(idObat);

      // Clear foto_key and foto_url in obat record
      await _client
          .from('obat')
          .update({'foto_key': null, 'foto_url': null}).eq('id_obat', idObat);

      await _removeFotoObjectIfExists(currentFotoUrl, swallowErrors: false);
    });
  }

  /// Ambil URL foto produk obat.
  Future<String?> getFotoObat(int idObat) async {
    return guard(() async {
      final response = await _client
          .from('obat')
          .select('foto_url')
          .eq('id_obat', idObat)
          .maybeSingle();

      if (response == null) return null;
      return response['foto_url'] as String?;
    });
  }

  String _buildUploadObjectPath({
    required int idObat,
    required String extension,
    Etalase? etalase,
    String? namaObat,
  }) {
    if (etalase != null && (namaObat ?? '').trim().isNotEmpty) {
      final snakeCase = namaObat!
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\s\-]+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      return '${etalase.value}/$snakeCase.webp';
    }
    // Legacy fallback: obat/{idObat}/{timestamp}.{ext}
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix =
        Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return 'obat/$idObat/$timestamp-$randomSuffix.$extension';
  }

  String? _extractFileExtension(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final dotIndex = trimmed.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex >= trimmed.length - 1) {
      return null;
    }

    return trimmed.substring(dotIndex + 1).toLowerCase();
  }

  String? _detectImageExtensionFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) {
      return 'webp';
    }

    return null;
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  String? _extractStoragePathFromFotoUrl(String? fotoUrl) {
    final raw = parseNullableString(fotoUrl);
    if (raw == null) {
      return null;
    }

    // Backward compatible: jika yang disimpan path langsung.
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      return raw.startsWith('/') ? raw.substring(1) : raw;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return null;
    }

    final bucketIndex = uri.pathSegments.indexOf(_fotoBucket);
    if (bucketIndex < 0 || bucketIndex >= uri.pathSegments.length - 1) {
      return null;
    }

    final encodedPath = uri.pathSegments.sublist(bucketIndex + 1).join('/');
    if (encodedPath.isEmpty) {
      return null;
    }

    return Uri.decodeComponent(encodedPath);
  }

  Future<void> _removeFotoObjectIfExists(
    String? fotoUrl, {
    required bool swallowErrors,
  }) async {
    final objectPath = _extractStoragePathFromFotoUrl(fotoUrl);
    if (objectPath == null) {
      return;
    }

    try {
      await _client.storage.from(_fotoBucket).remove([objectPath]);
    } catch (error) {
      if (!swallowErrors) {
        rethrow;
      }
    }
  }

  String _mapStorageUploadError(StorageException error) {
    final raw = error.message.toLowerCase();
    if (raw.contains('mime') || raw.contains('content type')) {
      return 'Format foto ditolak oleh server. Gunakan JPG, PNG, atau WEBP.';
    }
    if (raw.contains('size') || raw.contains('too large')) {
      return 'Ukuran foto melebihi batas server. Gunakan gambar yang lebih kecil.';
    }
    if (raw.contains('duplicate') || raw.contains('already exists')) {
      return 'Nama file foto bentrok. Coba pilih ulang gambar lalu simpan kembali.';
    }
    if (raw.contains('permission') || raw.contains('not authorized')) {
      return 'Anda tidak memiliki izin upload foto obat.';
    }
    return 'Upload foto obat gagal. Coba lagi.';
  }
}
