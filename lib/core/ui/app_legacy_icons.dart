import 'package:flutter/material.dart';

/// Registry ikon legacy Material yang dikembalikan dari Hugeicons.
///
/// File ini khusus untuk ikon-ikon tertentu yang perlu tampil dengan
/// gaya Material klasik (tidak menggunakan Hugeicons).
///
/// Gunakan dengan widget [Icon]:
/// ```dart
/// Icon(AppLegacyIcons.klinik, size: 36, color: Colors.white)
/// Icon(AppLegacyIcons.mail, size: 20, color: textMuted)
/// ```
///
/// Jangan campur dengan Hugeicons data — keep them separate.
class AppLegacyIcons {
  AppLegacyIcons._();

  // ─── Login ──────────────────────────────────────────────────────────────────

  /// Logo Klinik App — ikon plus dalam kotak
  /// Menggunakan `Icons.add_box_rounded` sebagai pengganti
  /// `AppIcons.klinik` (Hugeicons strokeRoundedHospital01)
  static const IconData klinik = Icons.add_box_rounded;

  /// Email / username — outline mail klasik
  /// Menggunakan `Icons.mail_outline_rounded` sebagai pengganti
  /// `AppIcons.mail` (Hugeicons strokeRoundedMail01)
  static const IconData mail = Icons.mail_outline_rounded;

  /// Password / lock — outline lock klasik
  /// Menggunakan `Icons.lock_outline_rounded` sebagai pengganti
  /// `AppIcons.lock` (Hugeicons strokeRoundedLock)
  static const IconData lock = Icons.lock_outline_rounded;

  /// Tampilkan password — visibility klasik
  /// Menggunakan `Icons.visibility_outlined` sebagai pengganti
  /// `AppIcons.eyeOn` (Hugeicons strokeRoundedEye)
  static const IconData visibilityOn = Icons.visibility_outlined;

  /// Sembunyikan password — visibility_off klasik
  /// Menggunakan `Icons.visibility_off_outlined` sebagai pengganti
  /// `AppIcons.eyeOff` (Hugeicons strokeRoundedEye)
  static const IconData visibilityOff = Icons.visibility_off_outlined;

  // ─── Theme Toggle ─────────────────────────────────────────────────────────────

  /// Light mode — ikon light_mode klasik
  /// Digunakan saat mode gelap aktif (tombol untuk switch ke light)
  /// Sebagai pengganti `AppIcons.sun` (Hugeicons strokeRoundedSun01)
  static const IconData lightMode = Icons.light_mode_rounded;

  /// Dark mode — ikon dark_mode klasik
  /// Digunakan saat mode terang aktif (tombol untuk switch ke dark)
  /// Sebagai pengganti `AppIcons.moon` (Hugeicons strokeRoundedMoon)
  static const IconData darkMode = Icons.dark_mode_outlined;
}
