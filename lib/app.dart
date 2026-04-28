import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';
import 'pages/dashboard_page.dart';
import 'pages/kehadiran_detail_page.dart';
import 'pages/kehadiran_form_page.dart';
import 'pages/kehadiran_tanggal_page.dart';
import 'pages/laporan_page.dart';
import 'pages/login_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/startup_page.dart';
import 'pages/obat_detail_page.dart';
import 'pages/obat_form_page.dart';
import 'pages/obat_keluar_detail_page.dart';
import 'pages/obat_keluar_form_page.dart';
import 'pages/obat_keluar_page.dart';
import 'pages/obat_keluar_tanggal_form_page.dart';
import 'pages/obat_masuk_detail_page.dart';
import 'pages/obat_masuk_form_page.dart';
import 'pages/obat_masuk_page.dart';
import 'pages/obat_masuk_tanggal_form_page.dart';
import 'pages/obat_hub_page.dart';
import 'pages/obat_page.dart';
import 'pages/sinkronisasi_stok_form_page.dart';
import 'pages/sinkronisasi_stok_page.dart';
import 'pages/pasien_detail_page.dart';
import 'pages/pasien_form_page.dart';
import 'pages/pasien_hub_page.dart';
import 'pages/pasien_page.dart';
import 'pages/kunjungan_form_page.dart';
import 'pages/transaksi_hub_page.dart';
import 'pages/transaksi_form_page.dart';

class KlinikApp extends StatelessWidget {
  const KlinikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeServiceInstance.notifier,
      builder: (context, _) {
        final mode = ThemeServiceInstance.notifier.mode;
        return MaterialApp(
          title: 'Klinik App',
          debugShowCheckedModeBanner: false,
          locale: const Locale('id', 'ID'),
          supportedLocales: const [
            Locale('id', 'ID'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          initialRoute: StartupPage.routeName,
          routes: {
            StartupPage.routeName: (_) => const StartupPage(),
            LoginPage.routeName: (_) => const LoginPage(),
            ForgotPasswordPage.routeName: (_) => const ForgotPasswordPage(),
            ResetPasswordPage.routeName: (_) => const ResetPasswordPage(),
            DashboardPage.routeName: (_) => const DashboardPage(),
            ObatPage.routeName: (_) => const ObatPage(),
            ObatHubPage.routeName: (_) => const ObatHubPage(),
            ObatDetailPage.routeName: (_) => const ObatDetailPage(),
            ObatFormPage.routeName: (_) => const ObatFormPage(),
            ObatMasukPage.routeName: (_) => const ObatMasukPage(),
            ObatMasukDetailPage.routeName: (_) => const ObatMasukDetailPage(),
            ObatMasukFormPage.routeName: (_) => const ObatMasukFormPage(),
            ObatMasukTanggalFormPage.routeName: (_) =>
                const ObatMasukTanggalFormPage(),
            SinkronisasiStokPage.routeName: (_) => const SinkronisasiStokPage(),
            // backward-compat legacy alias
            SinkronisasiStokPage.routeNameLegacy: (_) =>
                const SinkronisasiStokPage(),
            SinkronisasiStokFormPage.routeName: (_) =>
                const SinkronisasiStokFormPage(),
            // backward-compat legacy alias
            SinkronisasiStokFormPage.routeNameLegacy: (_) =>
                const SinkronisasiStokFormPage(),
            ObatKeluarPage.routeName: (_) => const ObatKeluarPage(),
            ObatKeluarDetailPage.routeName: (_) => const ObatKeluarDetailPage(),
            ObatKeluarFormPage.routeName: (_) => const ObatKeluarFormPage(),
            ObatKeluarTanggalFormPage.routeName: (_) =>
                const ObatKeluarTanggalFormPage(),
            PasienPage.routeName: (_) => const PasienPage(),
            PasienDetailPage.routeName: (_) => const PasienDetailPage(),
            PasienFormPage.routeName: (_) => const PasienFormPage(),
            PasienHubPage.routeName: (_) => const PasienHubPage(),
            KunjunganFormPage.routeName: (_) => const KunjunganFormPage(),
            KehadiranTanggalPage.routeName: (_) => const KehadiranTanggalPage(),
            KehadiranDetailPage.routeName: (_) => const KehadiranDetailPage(),
            KehadiranFormPage.routeName: (_) => const KehadiranFormPage(),
            LaporanPage.routeName: (_) => const LaporanPage(),
            TransaksiHubPage.routeName: (_) => const TransaksiHubPage(),
            TransaksiFormPage.routeName: (_) => const TransaksiFormPage(),
            // StrukPembayaranPage is accessed via direct widget instantiation in transaction flow
          },
        );
      },
    );
  }
}

/// Singleton accessor for the global [ThemeNotifier].
class ThemeServiceInstance {
  ThemeServiceInstance._();
  static final ThemeNotifier notifier = ThemeNotifier();
}
