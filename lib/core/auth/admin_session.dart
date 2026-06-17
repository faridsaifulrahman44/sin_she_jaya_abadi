import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/db_tables.dart';
import '../error/app_exception.dart';
import '../supabase/supabase_client_provider.dart';
import '../utils/parsers.dart';

/// Enum untuk role admin.
enum AdminRole {
  petugas,
  kepalaKlinik,
  unknown;

  /// Convert from DB string to enum.
  /// Handle both 'petugas' and 'kepala_klinik' (mapped to 'owner').
  static AdminRole fromString(String? value) {
    switch (value) {
      case 'petugas':
        return AdminRole.petugas;
      case 'kepala_klinik':
        return AdminRole.kepalaKlinik;
      default:
        return AdminRole.unknown;
    }
  }

  /// Check if this role is considered 'owner' level (kepala Klinik = owner).
  bool get isOwner => this == AdminRole.kepalaKlinik;

  /// Check if this role is 'petugas'.
  bool get isPetugas => this == AdminRole.petugas;

  /// Display name untuk UI.
  String get displayName {
    switch (this) {
      case AdminRole.petugas:
        return 'Petugas';
      case AdminRole.kepalaKlinik:
        return 'Owner';
      case AdminRole.unknown:
        return 'Tidak diketahui';
    }
  }
}

/// Helper untuk resolve `id_admin` aktif dari Supabase Auth session.
///
/// Perilaku default (aman untuk produksi):
/// - wajib ada session login
/// - wajib ada mapping admin.auth_user_id -> auth.users.id
/// - jika tidak valid, lempar exception eksplisit (tidak fallback diam-diam)
///
/// Fallback khusus development dapat diaktifkan eksplisit via:
/// --dart-define=ALLOW_DEV_ADMIN_FALLBACK=true
/// --dart-define=DEV_FALLBACK_ADMIN_ID=1
class AdminSession {
  const AdminSession._();

  static const bool _allowDevFallback =
      bool.fromEnvironment('ALLOW_DEV_ADMIN_FALLBACK', defaultValue: false);
  static const int _devFallbackAdminId =
      int.fromEnvironment('DEV_FALLBACK_ADMIN_ID', defaultValue: 1);
  static const String _devFallbackRole = String.fromEnvironment(
      'DEV_FALLBACK_ADMIN_ROLE',
      defaultValue: 'petugas');

  static int? _cachedAdminId;
  static String? _cachedAuthUserId;
  static AdminRole? _cachedRole;

  static bool get _canUseDevFallback => kDebugMode && _allowDevFallback;

  static void clearCache() {
    _cachedAdminId = null;
    _cachedAuthUserId = null;
    _cachedRole = null;
  }

  /// Mengembalikan `id_admin` aktif secara strict.
  ///
  /// Lempar [AuthRequiredException] jika session tidak ada.
  /// Lempar [AdminMappingException] jika mapping admin tidak ditemukan.
  static Future<int> getCurrentId() async {
    final user = SB.client.auth.currentUser;
    if (user == null) {
      clearCache();
      throw const AuthRequiredException(
        'Sesi login tidak ditemukan. Silakan login ulang.',
        code: 'auth_session_missing',
      );
    }

    if (_cachedAuthUserId == user.id &&
        _cachedAdminId != null &&
        _cachedAdminId! > 0) {
      return _cachedAdminId!;
    }

    Map<String, dynamic>? response;
    try {
      response = await SB.client
          .from(DbTables.admin)
          .select('${DbColumns.idAdmin}, ${DbColumns.role}')
          .eq(DbColumns.authUserId, user.id)
          .maybeSingle();
    } on PostgrestException catch (error) {
      throw AdminMappingException(
        'Gagal memverifikasi akun admin. Coba lagi.',
        code: 'admin_mapping_query_failed',
        cause: error,
        debugMessage:
            'PostgrestException code=${error.code} message=${error.message}',
      );
    }

    final idAdmin = parseInt(response?[DbColumns.idAdmin], fallback: 0);
    if (idAdmin > 0) {
      _cachedAdminId = idAdmin;
      _cachedAuthUserId = user.id;
      _cachedRole = AdminRole.fromString(response?[DbColumns.role] as String?);
      return idAdmin;
    }

    if (_canUseDevFallback && _devFallbackAdminId > 0) {
      debugPrint(
        '[AdminSession] DEV fallback aktif. '
        'auth_user_id=${user.id} -> id_admin=$_devFallbackAdminId, role=$_devFallbackRole',
      );
      _cachedAdminId = _devFallbackAdminId;
      _cachedAuthUserId = user.id;
      _cachedRole = AdminRole.fromString(_devFallbackRole);
      return _devFallbackAdminId;
    }

    clearCache();
    throw AdminMappingException(
      'Akun ini belum terhubung ke data admin. Hubungi kepala klinik.',
      code: 'admin_mapping_not_found',
      debugMessage: 'Tidak ada baris admin untuk auth_user_id=${user.id}',
    );
  }

  /// Mengembalikan role admin aktif.
  ///
  /// Secara otomatis memanggil [getCurrentId] jika belum ada cached data.
  /// Lempar exception yang sama seperti [getCurrentId].
  static Future<AdminRole> getRole() async {
    // Ensure admin is loaded first to get the role
    await getCurrentId();
    return _cachedRole ?? AdminRole.unknown;
  }

  /// Cek cepat apakah user adalah owner (kepala Klinik).
  /// Gunakan ini untuk permission check di UI.
  ///
  /// Note: Ini akan melakukan fetch jika belum ada cached role.
  static Future<bool> isOwner() async {
    final role = await getRole();
    return role.isOwner;
  }

  /// Cek cepat apakah user adalah petugas.
  /// Gunakan ini untuk permission check di UI.
  ///
  /// Note: Ini akan melakukan fetch jika belum ada cached role.
  static Future<bool> isPetugas() async {
    final role = await getRole();
    return role.isPetugas;
  }

  /// Cek cepat apakah user bisa melihat laporan.
  /// Owner = bisa, Petugas = tidak bisa.
  static Future<bool> canViewReports() async {
    final role = await getRole();
    return role.isOwner;
  }
}
