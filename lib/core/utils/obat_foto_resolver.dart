import '../supabase/supabase_config.dart';

/// Helper untuk resolve URL foto obat dari Supabase Storage.
///
/// ## Sumber prioritas
/// 1. `fotoKey` -> Supabase Storage bucket `obat-images`
/// 2. `fotoUrl` -> legacy URL field (fallback only)
///
/// ## Cache busting
/// Jika `fotoUpdatedAt` tersedia, ditambahkan sebagai query param `v`
/// sehingga browser/app mengambil versi baru saat foto di-update.
///
/// ## Perbaikan 2026-05-07
/// Menggunakan construction URL manual (bukan getPublicUrl) karena
/// getPublicUrl bisa double-encode karakter titik (.) di filename .webp,
/// menyebabkan 404 untuk file di root bucket seperti `die_da_tay_ping_yao_jing.webp`
/// sementara path subfolder tanpa titik di root path tetap berfungsi normal.
class ObatFotoResolver {
  ObatFotoResolver._();

  static const String _bucket = 'obat-images';

  /// Resolve URL lengkap untuk sebuah obat.
  ///
  /// Priority:
  /// 1. `fotoKey` -> storage URL dari bucket `obat-images`
  /// 2. `fotoUrl` -> legacy URL (fallback only)
  /// 3. `null` -> caller harus pakai placeholder
  static Uri? resolveStorageUrl({
    required String? fotoKey,
    required DateTime? fotoUpdatedAt,
    String? fotoUrl,
  }) {
    // Prioritas 1: fotoKey dari bucket Obat Storage
    final key = fotoKey?.trim();
    if (key != null && key.isNotEmpty) {
      final objectPath = key.startsWith('/') ? key.substring(1) : key;
      if (objectPath.isEmpty) return null;

      final baseUrl = _buildStorageUrl(objectPath);
      final uri = Uri.parse(baseUrl);

      // Cache busting via fotoUpdatedAt
      if (fotoUpdatedAt != null) {
        final version = fotoUpdatedAt.millisecondsSinceEpoch.toString();
        return uri.replace(queryParameters: {
          ...uri.queryParameters,
          'v': version,
        });
      }

      return uri;
    }

    // Prioritas 2: legacy fotoUrl (backward compat only)
    if (fotoUrl != null && fotoUrl.trim().isNotEmpty) {
      return Uri.tryParse(fotoUrl.trim());
    }

    return null;
  }

  /// Build raw storage public URL secara manual.
  ///
  /// Format: `https://project.supabase.co/storage/v1/object/public/bucket/path`
  /// Menghindari double-encoding titik oleh getPublicUrl().
  static String _buildStorageUrl(String objectPath) {
    // Extract project ref dari SupabaseConfig
    final uri = Uri.parse(SupabaseConfig.supabaseUrl);
    final projectRef = uri.host.split('.').first;

    // Build URL manual
    return 'https://$projectRef.supabase.co/storage/v1/object/public/$_bucket/$objectPath';
  }

  /// Convenience: cek apakah obat punya foto storage.
  static bool hasStorageFoto(String? fotoKey) {
    final key = fotoKey?.trim();
    return key != null && key.isNotEmpty;
  }

  /// Convenience: cek apakah harus pakai legacy fotoUrl fallback.
  static bool hasLegacyUrl(String? fotoUrl) {
    return fotoUrl != null && fotoUrl.trim().isNotEmpty;
  }
}
