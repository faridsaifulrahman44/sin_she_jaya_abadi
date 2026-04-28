/// Registry asset foto obat — sekarang hanya fallback / placeholder helper.
///
/// ## Peran
/// Source of truth foto obat sekarang adalah `foto_key` di database
/// + Supabase Storage bucket `obat-images`.
///
/// Registry ini TIDAK lagi jadi jalur utama.
/// Perannya sekarang hanya:
/// - Fallback ringan jika Supabase Storage gagal / unavailable
/// - Placeholder saat namaObat tersedia tapi foto belum diupload
/// - Helper normalize nama obat untuk debugging
///
/// ## Arsitektur foto obat saat ini (dari atas ke bawah)
/// 1. `foto_key` + `foto_updated_at` → Supabase Storage `obat-images` [PRIORITAS 1]
/// 2. `foto_url` legacy → backward compat only              [PRIORITAS 2]
/// 3. Registry ini → hanya jika 1 & 2 gagal                   [PRIORITAS 3]
///
/// ## Jangan tambahkan mapping obat baru di sini
/// Jika obat perlu foto, upload ke Supabase Storage dan set `foto_key`.
/// Registry hanya menyimpan placeholder/alias sederhana, bukan daftar obat lengkap.
class ObatAssetRegistry {
  ObatAssetRegistry._();

  /// Base path asset lokal (fallback only).
  static const String assetsBase = 'assets/images/obat';

  // ─── Placeholder asset (fallback sangat ringan) ──────────────────────────
  //
  // Sekarang registry TIDAK menyimpan daftar obat lengkap.
  // Hanya placeholder sederhana yang bisa dipakai saat asset tidak ditemukan.
  //
  // Jika Anda butuh menambahkan fallback asset baru:
  // 1. Pastikan asset tersebut benar-benar ada di `assets/images/obat/`
  // 2. Tambahkan SEMUA alias yang relevan
  // 3. Pastikan nama obat di Supabase cocok dengan alias di bawah
  //
  // HAPUS entry di bawah ini jika asset sudah tidak ada / tidak relevan.

  static const Map<String, String> _fallbackAssets = {
    // Placeholder untuk obat yang mungkin belum punya foto di Supabase Storage.
    // Nama key = nama file asset (tanpa path & extension).
    // Nama value  = display name untuk debugging.
    //
    // Obat baru tidak perlu ditambahkan di sini — cukup upload ke Supabase Storage.
    'placeholder': 'Placeholder',
  };

  /// Normalisasi nama obat untuk matching.
  ///
  /// Steps:
  /// 1. Trim whitespace
  /// 2. Lowercase
  /// 3. Replace multiple spaces with single space
  /// 4. Strip karakter non-alphanumeric kecuali spasi
  static String normalize(String nama) {
    return nama
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  }

  /// Resolve asset path untuk nama obat.
  ///
  /// Sekarang ini HANYA fallback prioritas 3.
  /// Returns null jika tidak ada fallback asset → caller harus pakai placeholder widget.
  static String? resolveAssetPath(String namaObat) {
    final key = normalize(namaObat);

    // Cek exact match di fallback assets
    for (final entry in _fallbackAssets.entries) {
      if (normalize(entry.key) == key) {
        return '$assetsBase/${entry.key}.png';
      }
    }

    return null;
  }

  /// Resolve asset path — fallback null jika tidak ditemukan.
  /// Gunakan [resolveAssetPath] jika perlu bedakan antara "ada asset" vs "placeholder".
  static String? resolve(String namaObat) => resolveAssetPath(namaObat);

  /// Cek apakah obat punya fallback asset.
  static bool hasAsset(String namaObat) => resolveAssetPath(namaObat) != null;

  /// List semua nama fallback asset (untuk debugging).
  static List<String> get registeredAssets => _fallbackAssets.keys.toList();
}
