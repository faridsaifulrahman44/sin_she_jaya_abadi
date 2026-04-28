import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper untuk resolve URL foto obat dari Supabase Storage.
///
///## Sumber prioritas
/// 1. `fotoKey` → Supabase Storage bucket `obat-images`
/// 2. `fotoUrl` → legacy URL field (fallback only)
///
///## Cache busting
/// Jika `fotoUpdatedAt` tersedia, ditambahkan sebagai query param `v`
/// sehingga browser/app mengambil versi baru saat foto di-update.
class ObatFotoResolver {
  ObatFotoResolver._();

  static const String _bucket = 'obat-images';
  static final _client = Supabase.instance.client;

  /// Resolve URL lengkap untuk sebuah obat.
  ///
  /// Priority:
  /// 1. `fotoKey` → storage URL dari bucket `obat-images`
  /// 2. `fotoUrl` → legacy URL (fallback only)
  /// 3. `null` → caller harus pakai placeholder
  static Uri? resolveStorageUrl({
    required String? fotoKey,
    required DateTime? fotoUpdatedAt,
    String? fotoUrl,
  }) {
    // ── Prioritas 1: fotoKey dari bucket Obat Storage ────────────────────────
    final key = fotoKey?.trim();
    if (key != null && key.isNotEmpty) {
      final objectPath = key.startsWith('/') ? key.substring(1) : key;
      final baseUrl = _client.storage.from(_bucket).getPublicUrl(objectPath);
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

    // ── Prioritas 2: legacy fotoUrl (backward compat only) ──────────────────
    if (fotoUrl != null && fotoUrl.trim().isNotEmpty) {
      return Uri.tryParse(fotoUrl.trim());
    }

    return null;
  }

  /// Convenience: cek apakah obat ini punya foto storage.
  static bool hasStorageFoto(String? fotoKey) {
    final key = fotoKey?.trim();
    return key != null && key.isNotEmpty;
  }

  /// Convenience: cek apakah harus pakai legacy fotoUrl fallback.
  static bool hasLegacyUrl(String? fotoUrl) {
    return fotoUrl != null && fotoUrl.trim().isNotEmpty;
  }
}
