import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'kehadiran_tab_content.dart';

/// Halaman route untuk "Daftar Kehadiran Pasien".
///
/// Wrapper scaffold di sekitar [KehadiranTabContent].
/// Jika diakses langsung via route, tampil normal.
/// Dirancang sebagai halaman standalone — navigasi dari dashboard
/// atau menu utama langsung ke halaman ini (tanpa hub tab).
class KehadiranPage extends StatelessWidget {
  const KehadiranPage({super.key, this.onRefresh});

  static const routeName = '/kehadiran';

  /// Callback opsional untuk refresh halaman setelah data tersimpan.
  /// Dipakai oleh [KehadiranTabContent] saat onRefresh selesai.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Daftar Kehadiran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: cteal(context),
        foregroundColor: conPrimary(context),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: cteal(context),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: KehadiranTabContent(onRefresh: onRefresh),
        ),
      ),
    );
  }
}