import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_exception.dart';
import '../supabase/supabase_client_provider.dart';

/// Result foto upload — berisi path Storage dan metadata.
class FotoUploadResult {
  const FotoUploadResult({
    required this.fotoKey,
    required this.publicUrl,
    required this.compressionInfo,
  });

  /// Path Storage di bucket `obat-images` (contoh: `etalase-1/nama_obat.webp`).
  final String fotoKey;

  /// URL publik lengkap untuk preview.
  final String publicUrl;

  /// Info kompresi untuk ditampilkan ke user.
  final String? compressionInfo;
}

/// Service end-to-end untuk upload foto obat ke Supabase Storage.
///
/// Alur: pick file → compress → upload → return fotoKey.
/// Service ini TIDAK menyentuh DB — gunakan [ObatRepository.updateFotoKey]
/// untuk menulis `foto_key` + `foto_updated_at` ke tabel `obat`.
class FotoObatUploadService {
  FotoObatUploadService({SupabaseClient? client})
      : _explicitClient = client;

  final SupabaseClient? _explicitClient;

  /// Lazy Supabase client — di-resolve saat pertama kali dipakai supaya
  /// test path-building tidak perlu inisialisasi Supabase.
  SupabaseClient get _client => _explicitClient ?? SB.client;

  static const String _bucket = 'obat-images';
  static const int _maxCompressedBytes = 800 * 1024; // 800 KB target
  static const int _maxInputBytes = 5 * 1024 * 1024; // 5 MB hard limit
  static const int _targetMaxDimension = 1280;
  static const int _jpegQuality = 82;
  static const int _pngKeepThresholdBytes = 350 * 1024;
  static const Set<String> _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// Upload foto obat ke Storage.
  ///
  /// [bytes] adalah file bytes yang sudah dipilih user.
  /// [fileName] adalah nama file asli (untuk deteksi ekstensi).
  /// [etalaseLabel] contoh: `"etalase1"`, `"etalase2"`.
  /// [namaObat] contoh: `"Die Da Tay Ping Yao Jing"`.
  ///
  /// Mengembalikan [FotoUploadResult] dengan fotoKey siap tulis ke DB.
  Future<FotoUploadResult> uploadFoto({
    required Uint8List bytes,
    required String fileName,
    required String etalaseLabel,
    required String namaObat,
  }) async {
    if (bytes.isEmpty) {
      throw const ValidationException('File gambar kosong.');
    }
    if (bytes.length > _maxInputBytes) {
      throw const ValidationException(
        'Ukuran foto maksimal 5 MB. Pilih gambar yang lebih kecil.',
        code: 'foto_too_large',
      );
    }

    // ── Compress ──────────────────────────────────────────────────────────
    final prepared = await _compressAndPrepare(
      sourceFileName: fileName,
      sourceBytes: bytes,
    );

    // ── Build Storage path ────────────────────────────────────────────────
    final objectPath = _buildObjectPath(
      etalaseLabel: etalaseLabel,
      namaObat: namaObat,
    );

    // ── Delete old foto if exists at same path (upsert-friendly) ──────────
    await deleteOldFoto(objectPath);

    // ── Upload ────────────────────────────────────────────────────────────
    try {
      await _client.storage.from(_bucket).uploadBinary(
            objectPath,
            prepared.bytes,
            fileOptions: FileOptions(
              contentType: _contentTypeForPath(objectPath),
              cacheControl: '31536000', // 1 year
              upsert: true,
            ),
          );
    } on StorageException catch (error) {
      throw ValidationException(
        _mapStorageError(error),
        code: error.statusCode,
        cause: error,
        debugMessage: error.toString(),
      );
    }

    final publicUrl = _client.storage.from(_bucket).getPublicUrl(objectPath);

    return FotoUploadResult(
      fotoKey: objectPath,
      publicUrl: publicUrl,
      compressionInfo: prepared.compressionInfo,
    );
  }

  /// Hapus foto lama dari Storage. Best effort — abaikan 404.
  Future<void> deleteOldFoto(String? fotoKey) async {
    if (fotoKey == null || fotoKey.trim().isEmpty) return;
    try {
      await _client.storage.from(_bucket).remove([fotoKey.trim()]);
    } catch (_) {
      // Best effort: abaikan error (termasuk 404 not found).
    }
  }

  /// Build object path sesuai format DB: `etalase-{N}/{slugified_nama}.webp`.
  ///
  /// Menerima [etalaseLabel] dalam format `"etalase1"` (dari Etalase.value)
  /// dan mengonversi ke `"etalase-1"` agar sinkron dengan foto_key existing.
  String buildFotoKey({
    required String etalaseLabel,
    required String namaObat,
  }) {
    return _buildObjectPath(
      etalaseLabel: etalaseLabel,
      namaObat: namaObat,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Build path: `etalase-{N}/{slugified_nama}.webp`
  String _buildObjectPath({
    required String etalaseLabel,
    required String namaObat,
  }) {
    final etalaseFolder = _normalizeEtalaseFolder(etalaseLabel);
    final slug = _slugify(namaObat);
    return '$etalaseFolder/$slug.webp';
  }

  /// Konversi `"etalase1"` → `"etalase-1"`, `"etalase2"` → `"etalase-2"`.
  String _normalizeEtalaseFolder(String raw) {
    final trimmed = raw.trim().toLowerCase();
    // Coba match pola "etalaseN" → "etalase-N"
    final match = RegExp(r'^etalase(\d+)$').firstMatch(trimmed);
    if (match != null) {
      return 'etalase-${match.group(1)}';
    }
    // Sudah benar atau format lain — kembalikan apa adanya
    return trimmed;
  }

  /// Slugify nama obat: lowercase, non-alphanumeric → underscore, trim.
  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Compress image bytes. Target: JPEG max 1280px, quality 82, ≤ 800 KB.
  /// Jika PNG kecil (≤ 350 KB), pertahankan sebagai PNG.
  Future<_CompressedFoto> _compressAndPrepare({
    required String sourceFileName,
    required Uint8List sourceBytes,
  }) async {
    final sourceExt = _extractExtension(sourceFileName);
    final shouldKeepPng =
        sourceExt == 'png' && sourceBytes.length <= _pngKeepThresholdBytes;

    final targetFormat =
        shouldKeepPng ? CompressFormat.png : CompressFormat.jpeg;
    final quality = shouldKeepPng ? 100 : _jpegQuality;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        sourceBytes,
        minWidth: _targetMaxDimension,
        minHeight: _targetMaxDimension,
        quality: quality,
        format: targetFormat,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (compressed.isEmpty) {
        throw const FormatException('Foto hasil kompresi kosong.');
      }

      final resultBytes = Uint8List.fromList(compressed);

      // Jika masih > 800 KB, coba kompres ulang dengan quality lebih rendah
      if (resultBytes.length > _maxCompressedBytes && !shouldKeepPng) {
        final reCompressed = await FlutterImageCompress.compressWithList(
          sourceBytes,
          minWidth: _targetMaxDimension,
          minHeight: _targetMaxDimension,
          quality: 60,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (reCompressed.isNotEmpty) {
          final retry = Uint8List.fromList(reCompressed);
          return _CompressedFoto(
            bytes: retry,
            compressionInfo: _buildCompressionInfo(
              originalSize: sourceBytes.length,
              compressedSize: retry.length,
            ),
          );
        }
      }

      return _CompressedFoto(
        bytes: resultBytes,
        compressionInfo: _buildCompressionInfo(
          originalSize: sourceBytes.length,
          compressedSize: resultBytes.length,
        ),
      );
    } catch (_) {
      // Fallback: gunakan file asli jika format diizinkan
      if (sourceExt != null && _allowedExtensions.contains(sourceExt)) {
        return _CompressedFoto(
          bytes: sourceBytes,
          compressionInfo: 'Kompresi gagal, file asli dipakai sebagai fallback.',
        );
      }
      rethrow;
    }
  }

  String _buildCompressionInfo({
    required int originalSize,
    required int compressedSize,
  }) {
    final original = _formatSize(originalSize);
    final compressed = _formatSize(compressedSize);
    if (compressedSize >= originalSize) {
      return 'Foto diproses ($compressed).';
    }
    final saved = ((originalSize - compressedSize) * 100 / originalSize)
        .clamp(0, 100)
        .round();
    return 'Foto dikompresi: $original → $compressed ($saved% lebih kecil).';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  String? _extractExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot >= fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  String _contentTypeForPath(String path) {
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String _mapStorageError(StorageException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('mime') || msg.contains('content type')) {
      return 'Format foto ditolak oleh server. Gunakan JPG, PNG, atau WEBP.';
    }
    if (msg.contains('size') || msg.contains('too large')) {
      return 'Ukuran foto melebihi batas server.';
    }
    if (msg.contains('permission') || msg.contains('not authorized')) {
      return 'Anda tidak memiliki izin upload foto obat.';
    }
    return 'Upload foto obat gagal. Coba lagi.';
  }
}

class _CompressedFoto {
  const _CompressedFoto({required this.bytes, this.compressionInfo});
  final Uint8List bytes;
  final String? compressionInfo;
}
