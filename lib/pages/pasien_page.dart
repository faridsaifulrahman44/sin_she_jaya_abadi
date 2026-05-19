import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'pasien_tab_content.dart';

/// Halaman route untuk "Pasien".
///
/// Wrapper scaffold di sekitar [PasienTabContent].
/// Jika diakses langsung via route, tampil normal.
/// Jika di-embed di [PasienHubPage], gunakan [PasienTabContent] langsung.
class PasienPage extends StatelessWidget {
  const PasienPage({super.key, this.onRefresh});

  static const routeName = '/pasien';

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Pasien',
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
          child: PasienTabContent(onRefresh: onRefresh),
        ),
      ),
    );
  }
}
