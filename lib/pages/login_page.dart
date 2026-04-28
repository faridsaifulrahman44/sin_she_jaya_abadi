import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/admin_session.dart';
import '../core/auth/auth_email_helper.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import 'dashboard_page.dart';
import 'forgot_password_page.dart';
import 'login/widgets/login_layouts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const routeName = '/';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _routeMessageHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeMessageHandled) return;
    _routeMessageHandled = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final message = switch (args) {
      String value when value.trim().isNotEmpty => value.trim(),
      Map<String, dynamic> value when value['message'] is String =>
        (value['message'] as String).trim(),
      _ => '',
    };

    if (message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAuthError(message);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showAuthError(String message) {
    showModernSnackBar(
      context,
      message,
      isError: true,
      icon: AppIcons.error,
    );
  }

  Future<void> _login() async {
    final emailRaw = _emailController.text;
    final passwordRaw = _passwordController.text;

    if (!AuthEmailHelper.isValid(emailRaw)) {
      _showAuthError('Email atau username harus diisi dengan benar');
      return;
    }
    if (passwordRaw.trim().isEmpty) {
      _showAuthError('Password harus diisi');
      return;
    }

    // Normalisasi: shorthand Gmail → email lengkap
    final email = AuthEmailHelper.normalize(emailRaw);

    try {
      setState(() => _loading = true);
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: passwordRaw.trim(),
      );

      // Validasi mapping admin setelah login agar audit trail aman.
      await AdminSession.getCurrentId();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, DashboardPage.routeName);
    } catch (error, stackTrace) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      AdminSession.clearCache();

      if (!mounted) return;
      _showAuthError(AppErrorMapper.toMessage(error, stackTrace));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _openForgotPassword() {
    Navigator.pushNamed(context, ForgotPasswordPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return LoginDesktopLayout(
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                loading: _loading,
                onTogglePassword: _togglePasswordVisibility,
                onLogin: _login,
                onForgotPassword: _openForgotPassword,
              );
            }

            return LoginMobileLayout(
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              loading: _loading,
              onTogglePassword: _togglePasswordVisibility,
              onLogin: _login,
              onForgotPassword: _openForgotPassword,
            );
          },
        ),
      ),
    );
  }
}
