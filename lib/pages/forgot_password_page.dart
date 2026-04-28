import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/auth_email_helper.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/ui/app_legacy_icons.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? get _emailError {
    final input = _emailController.text;
    if (!AuthEmailHelper.isValid(input)) {
      return 'Username atau email tidak valid';
    }
    return null;
  }

  Future<void> _sendReset() async {
    if (!AuthEmailHelper.isValid(_emailController.text)) {
      setState(() {});
      return;
    }

    // Normalisasi: shorthand Gmail → email lengkap
    final email = AuthEmailHelper.normalize(_emailController.text);

    try {
      setState(() => _loading = true);
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (error, stackTrace) {
      if (!mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
        icon: AppIcons.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final primaryColor = cprimary(context);
    final navyColor = cnavy(context);

    return Scaffold(
      backgroundColor: cscaffoldBg(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(AppLegacyIcons.klinik, color: navyColor, size: 28),
          onPressed: () => Navigator.pushReplacementNamed(
            context,
            LoginPage.routeName,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 520;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 0 : 24,
                vertical: 16,
              ),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isWide ? 480 : 600),
                  padding: EdgeInsets.all(isWide ? 48 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isWide) ...[
                        // Logo
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: navyColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: navyColor.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              AppLegacyIcons.klinik,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      if (_submitted) ...[
                        _SuccessState(
                          email:
                              AuthEmailHelper.normalize(_emailController.text),
                          onBack: () => Navigator.pushReplacementNamed(
                            context,
                            LoginPage.routeName,
                          ),
                        ),
                      ] else ...[
                        // Icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: HugeIcon(
                            icon: AppIcons.lock,
                            color: primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'Lupa Password?',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan alamat email yang terdaftar. '
                          'Kami akan mengirim tautan untuk mereset password.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Email field
                        _EmailField(
                          controller: _emailController,
                          error: _emailError,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _sendReset(),
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        _SubmitButton(
                          loading: _loading,
                          enabled: _emailController.text.trim().isNotEmpty,
                          onTap: _sendReset,
                        ),
                        const SizedBox(height: 20),

                        // Back link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              LoginPage.routeName,
                            ),
                            child: Text(
                              'Kembali ke halaman login',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  const _EmailField({
    required this.controller,
    required this.error,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final textMuted = ctextMuted(context);
    final dangerColor = cdanger(context);

    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username / Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ctextPrimary(context),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? dangerColor : dividerColor,
              width: hasError ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: 'username atau email',
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              prefixIcon: Icon(
                AppLegacyIcons.mail,
                color: hasError ? dangerColor : textMuted,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: TextStyle(
              fontSize: 12,
              color: dangerColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = cprimary(context);
    final isReady = !loading && enabled;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isReady
            ? primaryColor
            : (cisDark(context) ? DarkColors.divider : Colors.grey[300]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReady ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cisDark(context)
                            ? DarkColors.textSecondary
                            : Colors.grey[600]!,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HugeIcon(
                        icon: AppIcons.send,
                        color: isReady ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kirim Tautan Reset',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isReady ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.onBack,
  });

  final String email;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final primaryColor = cprimary(context);
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final cardBg = ccardBg(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: AppIcons.success,
            color: primaryColor,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Cek Email Anda',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cdivider(context)),
          ),
          child: Column(
            children: [
              Text(
                'Tautan reset password telah dikirim ke:',
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Buka email Anda dan klik tautan "Reset Password" untuk '
          'membuat password baru. Tautan berlaku selama 1 jam.',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Back button
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: Center(
                child: Text(
                  'Kembali ke Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
