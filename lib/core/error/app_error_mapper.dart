import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

class AppErrorMapper {
  static AppException map(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (error is AppException) {
      return error;
    }

    if (error is TimeoutException) {
      return NetworkException(
        'Koneksi ke server terlalu lama. Coba lagi.',
        code: 'timeout',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'timeout',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    if (error is PostgrestException) {
      return DatabaseException(
        _mapPostgrestMessage(error),
        code: error.code,
        cause: error,
        debugMessage: _buildPostgrestDebug(error, stackTrace),
      );
    }

    if (error is AuthException) {
      return AuthRequiredException(
        _mapAuthMessage(error),
        code: error.statusCode,
        cause: error,
        debugMessage: _buildDebugSummary(
          code: error.statusCode,
          rawMessage: error.message,
          stackTrace: stackTrace,
        ),
      );
    }

    if (error is FormatException) {
      return ValidationException(
        'Format data tidak valid.',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'format',
          rawMessage: error.message,
          stackTrace: stackTrace,
        ),
      );
    }

    final lowerError = error.toString().toLowerCase();

    if (_isTimeoutIssue(lowerError)) {
      return NetworkException(
        'Koneksi ke server terlalu lama. Coba lagi.',
        code: 'timeout',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'timeout',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    if (_isNetworkPermissionDenied(lowerError)) {
      return NetworkException(
        'Aplikasi belum memiliki izin internet pada perangkat ini. '
        'Perbarui aplikasi lalu coba lagi.',
        code: 'network_permission_denied',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'network_permission_denied',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    if (_isTlsHandshakeIssue(lowerError)) {
      return NetworkException(
        'Koneksi aman ke server gagal (SSL/TLS). '
        'Periksa tanggal & waktu perangkat atau coba jaringan lain.',
        code: 'tls_handshake',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'tls_handshake',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    if (_isDnsIssue(lowerError)) {
      return NetworkException(
        'Server tidak ditemukan. Periksa koneksi atau konfigurasi server.',
        code: 'dns_lookup_failed',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'dns_lookup_failed',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    if (_isClientNetworkIssue(lowerError)) {
      return NetworkException(
        'Tidak dapat terhubung ke internet. Periksa koneksi Anda.',
        code: 'network',
        cause: error,
        debugMessage: _buildDebugSummary(
          code: 'network',
          rawMessage: error.toString(),
          stackTrace: stackTrace,
        ),
      );
    }

    return UnknownAppException(
      'Terjadi kesalahan yang tidak terduga. Coba lagi.',
      cause: error,
      debugMessage: _buildDebugSummary(
        code: error.runtimeType.toString(),
        rawMessage: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  }

  static String toMessage(Object error, [StackTrace? stackTrace]) {
    return _toMessage(error, stackTrace, includeDebugInfo: kDebugMode);
  }

  static String toMessageWithDebug(
    Object error, [
    StackTrace? stackTrace,
    bool includeDebugInfo = true,
  ]) {
    return _toMessage(error, stackTrace, includeDebugInfo: includeDebugInfo);
  }

  static String _toMessage(
    Object error,
    StackTrace? stackTrace, {
    required bool includeDebugInfo,
  }) {
    final mapped = map(error, stackTrace);
    if (!includeDebugInfo) return mapped.userMessage;

    final debugParts = <String>[
      if ((mapped.code ?? '').trim().isNotEmpty) 'code=${mapped.code}',
      if ((mapped.debugMessage ?? '').trim().isNotEmpty)
        mapped.debugMessage!.trim(),
    ];
    if (debugParts.isEmpty) return mapped.userMessage;

    return '${mapped.userMessage}\n[debug] ${debugParts.join(' | ')}';
  }

  static String _mapAuthMessage(AuthException error) {
    final msg = error.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password') ||
        msg.contains('invalid credentials')) {
      return 'Email atau password salah. Periksa kembali.';
    }

    if (msg.contains('user already registered') ||
        msg.contains('already registered')) {
      return 'Akun dengan email ini sudah terdaftar.';
    }

    if (msg.contains('user not found') ||
        msg.contains('no user') ||
        msg.contains('not found')) {
      return 'Akun tidak ditemukan.';
    }

    if (msg.contains('email not confirmed') ||
        msg.contains('email not verified') ||
        msg.contains('signup is disabled')) {
      return 'Email belum diverifikasi atau akun belum aktif.';
    }

    if (msg.contains('weak password') || msg.contains('password')) {
      return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
    }

    if (msg.contains('rate limit') || msg.contains('too many request')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat.';
    }

    if (msg.contains('token')) {
      return 'Sesi tidak valid atau sudah kedaluwarsa.';
    }

    return 'Autentikasi gagal. Periksa email dan password Anda.';
  }

  static String _mapPostgrestMessage(PostgrestException error) {
    final message = error.message.toLowerCase();
    final details = (error.details ?? '').toString().toLowerCase();
    final hint = (error.hint ?? '').toString().toLowerCase();

    if (error.code == '23505' || message.contains('duplicate')) {
      return 'Data yang sama sudah tersedia.';
    }

    if (error.code == '23503' ||
        message.contains('foreign key') ||
        details.contains('foreign key')) {
      return 'Data tidak dapat diproses karena masih terhubung dengan data lain.';
    }

    if (error.code == '23514') {
      // Check constraint violated (e.g. obat_etalase_check, stok_*_check).
      if (hint.contains('obat_etalase_check') ||
          details.contains('obat_etalase_check') ||
          message.contains('etalase')) {
        return 'Etalase yang dipilih tidak valid. '
            'Pilih Etalase 1, 2, atau 3.';
      }
      if (hint.toLowerCase().contains('check_stock_failed') ||
          message.toLowerCase().contains('oversell') ||
          details.toLowerCase().contains('check_stock_failed')) {
        return 'Stok tidak mencukupi. '
            'Periksa kembali jumlah yang diminta.';
      }
      return 'Data tidak memenuhi aturan yang berlaku.';
    }

    if (error.code == '42501' ||
        message.contains('row-level security') ||
        message.contains('permission') ||
        details.contains('permission') ||
        hint.contains('permission')) {
      return 'Akses ke data ditolak.';
    }

    if (error.code == 'PGRST116' || message.contains('not found')) {
      return 'Data yang diminta tidak ditemukan.';
    }

    return 'Terjadi kendala saat mengakses database.';
  }

  static String _buildPostgrestDebug(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    final parts = <String>[
      if ((error.code ?? '').trim().isNotEmpty) 'pg_code=${error.code}',
      if (error.message.trim().isNotEmpty) 'message=${_trim(error.message)}',
      if ((error.details ?? '').toString().trim().isNotEmpty)
        'details=${_trim((error.details ?? '').toString())}',
      if ((error.hint ?? '').toString().trim().isNotEmpty)
        'hint=${_trim((error.hint ?? '').toString())}',
    ];

    final stackTop = _stackTop(stackTrace);
    if (stackTop.isNotEmpty) {
      parts.add('stack=$stackTop');
    }
    return parts.join(' | ');
  }

  static String _buildDebugSummary({
    String? code,
    required String rawMessage,
    StackTrace? stackTrace,
  }) {
    final parts = <String>[
      if ((code ?? '').trim().isNotEmpty) 'code=$code',
      if (rawMessage.trim().isNotEmpty) 'message=${_trim(rawMessage)}',
    ];

    final stackTop = _stackTop(stackTrace);
    if (stackTop.isNotEmpty) {
      parts.add('stack=$stackTop');
    }
    return parts.join(' | ');
  }

  static bool _isTimeoutIssue(String lowerError) {
    return lowerError.contains('timeoutexception') ||
        lowerError.contains('timed out');
  }

  static bool _isNetworkPermissionDenied(String lowerError) {
    return lowerError.contains('socketexception') &&
        (lowerError.contains('permission denied') ||
            lowerError.contains('operation not permitted') ||
            lowerError.contains('errno = 1') ||
            lowerError.contains('errno = 13'));
  }

  static bool _isTlsHandshakeIssue(String lowerError) {
    return lowerError.contains('handshakeexception') ||
        lowerError.contains('certificate verify failed') ||
        lowerError.contains('certpathvalidatorexception') ||
        lowerError.contains('ssl error') ||
        lowerError.contains('tls handshake') ||
        lowerError.contains('tlsv');
  }

  static bool _isDnsIssue(String lowerError) {
    return lowerError.contains('failed host lookup') ||
        lowerError.contains('no address associated with hostname') ||
        lowerError.contains('name or service not known') ||
        lowerError.contains('nodename nor servname') ||
        lowerError.contains('unknown host') ||
        lowerError.contains('getaddrinfo');
  }

  static bool _isClientNetworkIssue(String lowerError) {
    return lowerError.contains('socketexception') ||
        lowerError.contains('clientexception') ||
        lowerError.contains('connection refused') ||
        lowerError.contains('network is unreachable') ||
        lowerError.contains('connection reset') ||
        lowerError.contains('broken pipe') ||
        lowerError.contains('no route to host');
  }

  static String _stackTop(StackTrace? stackTrace) {
    if (stackTrace == null) return '';
    final lines = stackTrace.toString().trim().split('\n');
    if (lines.isEmpty) return '';
    return _trim(lines.first.trim());
  }

  static String _trim(String text, {int max = 180}) {
    if (text.length <= max) return text;
    return '${text.substring(0, max)}...';
  }
}
