import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/ui/app_legacy_icons.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  static const routeName = '/reset-password';

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _completed = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      final pw = _passwordController.text;
      _passwordError = _getPasswordError(pw);
      _confirmError = _getConfirmError(pw, _confirmController.text);
    });
  }

  String? _getPasswordError(String password) {
    if (password.isEmpty) return 'Password wajib diisi';
    if (password.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _getConfirmError(String password, String confirm) {
    if (confirm.isEmpty) return 'Konfirmasi password wajib diisi';
    if (confirm != password) return 'Password tidak cocok';
    return null;
  }

  bool get _isFormValid {
    return _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _passwordError == null &&
        _confirmError == null;
  }

  Future<void> _submit() async {
    _validate();
    if (_passwordError != null || _confirmError != null) return;

    try {
      setState(() => _loading = true);
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
        ),
      );
      if (!mounted) return;
      setState(() => _completed = true);
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
                      if (_completed) ...[
                        _CompletedState(
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
                          'Buat Password Baru',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan password baru untuk akun Anda.',
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Password field
                        _PasswordField(
                          label: 'Password Baru',
                          controller: _passwordController,
                          hint: 'Minimal 6 karakter',
                          icon: AppLegacyIcons.lock,
                          error: _passwordError,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          onChanged: (_) => _validate(),
                          onSubmitted: (_) {},
                        ),
                        const SizedBox(height: 16),

                        // Confirm password field
                        _PasswordField(
                          label: 'Konfirmasi Password',
                          controller: _confirmController,
                          hint: 'Masukkan password yang sama',
                          icon: AppLegacyIcons.lock,
                          error: _confirmError,
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          onChanged: (_) => _validate(),
                          onSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        _SubmitButton(
                          loading: _loading,
                          enabled: _isFormValid,
                          onTap: _submit,
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
                              'Batal',
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.error,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? error;
  final bool obscure;
  final VoidCallback onToggle;
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
          label,
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
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textMuted, fontSize: 14),
              prefixIcon: Icon(
                icon,
                color: hasError ? dangerColor : textMuted,
                size: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure
                      ? AppLegacyIcons.visibilityOff
                      : AppLegacyIcons.visibilityOn,
                  color: textMuted,
                  size: 20,
                ),
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
                      const Icon(
                        Icons.lock_open_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Simpan Password Baru',
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

class _CompletedState extends StatelessWidget {
  const _CompletedState({required this.onBack});

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
          'Password Berhasil Diubah',
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
          child: Text(
            'Password akun Anda telah berhasil diperbarui. '
            'Silakan masuk dengan password baru.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),

        // Back to login button
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
                  'Masuk dengan Password Baru',
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
