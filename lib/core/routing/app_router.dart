import 'package:go_router/go_router.dart';

import '../../pages/dashboard_page.dart';
import '../../pages/login_page.dart';
import '../../pages/startup_page.dart';
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
          path: TransaksiHubPage.routeName,
          name: 'transaksi-hub',
          builder: (context, state) => const TransaksiHubPage(),
        ),
      ],
    );
  }
}
