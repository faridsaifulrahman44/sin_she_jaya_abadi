import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'kehadiran_tab_content.dart';

/// Halaman route untuk "Daftar Hadir" per tanggal.
///
/// Wrapper scaffold di sekitar [KehadiranTabContent].
/// Jika diakses langsung via route, tampil normal.
class KehadiranTanggalPage extends StatelessWidget {
  const KehadiranTanggalPage({super.key});

  static const routeName = '/kehadiran-tanggal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Daftar Hadir',
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
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: const SafeArea(
          top: false,
          child: KehadiranTabContent(),
        ),
      ),
    );
  }
}
