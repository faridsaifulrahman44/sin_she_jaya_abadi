import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import 'dashboard_page.dart';
import 'login_page.dart';

/// Halaman landing singkat untuk validasi session login dan mapping admin.
///
/// Jika session valid + mapping admin ditemukan -> Dashboard.
/// Jika tidak valid -> kembali ke Login dengan pesan error yang jelas.
class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  static const routeName = '/startup';

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final auth = Supabase.instance.client.auth;
    final hasSession = auth.currentSession != null;
    if (!hasSession) {
      Navigator.pushReplacementNamed(context, LoginPage.routeName);
      return;
    }

    try {
      // Preload role agar ready saat di dashboard
      await AdminSession.getRole();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, DashboardPage.routeName);
    } catch (error, stackTrace) {
      try {
        await auth.signOut();
      } catch (_) {}
      AdminSession.clearCache();

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        LoginPage.routeName,
        arguments: AppErrorMapper.toMessage(error, stackTrace),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
