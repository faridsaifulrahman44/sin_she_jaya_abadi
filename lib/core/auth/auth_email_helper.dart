/// Helper normalisasi email untuk alur autentikasi.
///
/// Semua input user (login, forgot password) diproses melalui helper ini
/// agar shorthand Gmail (tanpa @gmail.com) konsisten ditangani.
///
/// Aturan:
/// - `pegawai01`        → `pegawai01@gmail.com`
/// - `pegawai01@gmail.com` → `pegawai01@gmail.com` (apa adanya)
/// - spasi kosong di-trim, semua huruf jadi lowercase
class AuthEmailHelper {
  const AuthEmailHelper._();

  static const String _domain = 'gmail.com';

  /// Normalisasi input email/useran ke format lengkap.
  ///
  /// - trim whitespace
  /// - lowercase
  /// - jika tanpa `@`, append `@gmail.com`
  /// - jika sudah mengandung `@`, kembalikan apa adanya (sudah ter-trim & lowercase)
  static String normalize(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.contains('@')) return '$trimmed@$_domain';
    return trimmed;
  }

  /// Validasi input email/useran.
  ///
  /// Menerima:
  /// - username tanpa @  (misal `pegawai01`)
  /// - email lengkap     (misal `pegawai01@gmail.com`)
  /// - format lain yang wajar (user@domain.com)
  static bool isValid(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;

    if (!trimmed.contains('@')) {
      // Username shorthand: alphanumeric, underscore, dot, hyphen — min 1 karakter
      return RegExp(r'^[\w.\-]+$').hasMatch(trimmed);
    }

    // Email lengkap: basic format validation
    return RegExp(r'^[\w.\-]+@[\w.\-]+\.\w{2,}$').hasMatch(trimmed);
  }

  /// Kembalikan string yang aman ditampilkan ke user.
  /// Jika shorthand, tampilkan apa yang user ketik (sebelum normalisasi).
  static String toDisplay(String input) {
    return input.trim();
  }
}
