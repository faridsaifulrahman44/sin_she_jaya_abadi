import 'package:go_router/go_router.dart';

import '../../pages/dashboard_page.dart';
import '../../pages/kehadiran_page.dart';
import '../../pages/login_page.dart';
import '../../pages/pasien_page.dart';
import '../../pages/startup_page.dart';
import '../../pages/stok_alert_page.dart';
import '../../pages/transaksi_hub_page.dart';

/// Progressive go_router migration scaffold.
///
/// Catatan:
/// - Belum diaktifkan penuh agar kompatibel dengan alur `Navigator.pushNamed`
///   existing yang masih dipakai lintas fitur.
/// - Route inti disiapkan agar migrasi bertahap lebih aman.
class AppRouter {
  const AppRouter._();

  static GoRouter build() {
    return GoRouter(
      initialLocation: StartupPage.routeName,
      routes: [
        GoRoute(
          path: StartupPage.routeName,
          name: 'startup',
          builder: (context, state) => const StartupPage(),
        ),
        GoRoute(
          path: LoginPage.routeName,
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: DashboardPage.routeName,
          name: 'dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: PasienPage.routeName,
          name: 'pasien',
          builder: (context, state) => const PasienPage(),
        ),
        GoRoute(
          path: KehadiranPage.routeName,
          name: 'kehadiran',
          builder: (context, state) => const KehadiranPage(),
        ),
        GoRoute(
          path: TransaksiHubPage.routeName,
          name: 'transaksi-hub',
          builder: (context, state) => const TransaksiHubPage(),
        ),
        GoRoute(
          path: StokAlertPage.routeName,
          name: 'stok-alert',
          builder: (context, state) => const StokAlertPage(),
        ),
      ],
    );
  }
}
