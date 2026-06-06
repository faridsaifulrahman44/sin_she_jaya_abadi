import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_legacy_icons.dart';
import '../../../core/ui/app_symbols.dart';

class LoginMobileLayout extends StatelessWidget {
  const LoginMobileLayout({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final textMuted = ctextMuted(context);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Wallpaper zone: soft teal gradient with medical cross watermark ──
          Expanded(
            flex: 38,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Stack(
                children: [
                  // Faded medical cross watermark (top-right, opacity 12%)
                  Positioned(
                    top: AppSpacing.xxl,
                    right: AppSpacing.xxl,
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(
                        Symbols.health_and_safety_rounded,
                        size: AppRadius.size160,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // Center: logo + clinic name
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Soft-white circular badge with medical icon
                        Container(
                          width: AppRadius.size88,
                          height: AppRadius.size88,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Symbols.medical_services_rounded,
                            size: AppRadius.size44,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md14),
                        const Text(
                          'SinShe Jaya Abadi',
                          style: TextStyle(
                            fontSize: AppRadius.size22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs6),
                        Text(
                          'Klinik Herbal Tradisional',
                          style: TextStyle(
                            fontSize: AppRadius.size12half,
                            color: Colors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Form zone: white card dengan top radius 28, no shadow upward ─────
          Expanded(
            flex: 62,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.size28),
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppRadius.size28, AppSpacing.xxl, AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome text — left-aligned, 22px w800
                    Text(
                      'Selamat Datang',
                      style: AppTextStyles.headlineLg.copyWith(
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs6),
                    Text(
                      'Masuk untuk melanjutkan ke dashboard klinik',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontSize: AppRadius.size13half,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Email label — small-caps style
                    Text(
                      'EMAIL',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Email field — soft fill style (Stitch login_premium)
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        fontSize: AppRadius.size14,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: AppRadius.size14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          AppLegacyIcons.mail,
                          color: textMuted,
                          size: AppRadius.size20,
                        ),
                        filled: true,
                        fillColor: AppColors.legacySlate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppRadius.size16,
                          vertical: AppRadius.size16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Password label
                    Text(
                      'PASSWORD',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: AppRadius.size11,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Password field — soft fill style
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onLogin(),
                      style: TextStyle(
                        fontSize: AppRadius.size14,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: AppRadius.size14,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          AppLegacyIcons.lock,
                          color: textMuted,
                          size: AppRadius.size20,
                        ),
                        suffixIcon: GestureDetector(
                          onTap: onTogglePassword,
                          child: Icon(
                            obscurePassword
                                ? AppLegacyIcons.visibilityOff
                                : AppLegacyIcons.visibilityOn,
                            color: textMuted,
                            size: AppRadius.size20,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.legacySlate50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppRadius.size16,
                          vertical: AppRadius.size16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Forgot password — right-aligned
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm10),
                        child: GestureDetector(
                          onTap: onForgotPassword,
                          child: Text(
                            'Lupa password?',
                            style: TextStyle(
                              fontSize: AppRadius.size12half,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Login button — solid teal, full width, AppRadius.md
                    SizedBox(
                      height: AppRadius.size52,
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(77),
                              blurRadius: AppRadius.size14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: loading ? null : onLogin,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      width: AppRadius.size22,
                                      height: AppRadius.size22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          AppSymbols.login,
                                          color: Colors.white,
                                          size: AppRadius.size20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm10),
                                        const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: AppRadius.size15half,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Info hubungi admin — soft fill style
                    Container(
                      padding: const EdgeInsets.all(AppRadius.size12),
                      decoration: BoxDecoration(
                        color: AppColors.legacySlate50,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: textMuted,
                            size: AppRadius.size16,
                          ),
                          const SizedBox(width: AppSpacing.sm10),
                          Expanded(
                            child: Text(
                              'Belum punya akun? Hubungi admin klinik untuk dibuatkan akun.',
                              style: TextStyle(
                                fontSize: AppRadius.size11half,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppRadius.size18),

                    // Copyright
                    Center(
                      child: Text(
                        '© 2026 SinShe Jaya Abadi',
                        style: TextStyle(
                          fontSize: AppRadius.size11,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + AppRadius.size16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginDesktopLayout extends StatelessWidget {
  const LoginDesktopLayout({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.loading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool loading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = cscaffoldBg(context);
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final textMuted = ctextMuted(context);
    final primaryColor = cprimary(context);
    final navyColor = cnavy(context);

    return Column(
      children: [
        _DesktopBrandingSection(navyColor: navyColor),
        Expanded(
          child: Container(
            color: scaffoldBg,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: dividerColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              AppSymbols.wavingHand,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          _LoginWelcomeText(
                            titleColor: textPrimary,
                            subtitleColor: textSecondary,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _LoginFieldLabel(label: 'Email'),
                      const SizedBox(height: AppSpacing.sm),
                      _LoginTextField(
                        controller: emailController,
                        hint: 'username atau nama@email.com',
                        icon: AppLegacyIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _LoginFieldLabel(label: 'Password'),
                      const SizedBox(height: AppSpacing.sm),
                      _LoginTextField(
                        controller: passwordController,
                        hint: 'Masukkan password',
                        icon: AppLegacyIcons.lock,
                        obscure: obscurePassword,
                        suffix: GestureDetector(
                          onTap: onTogglePassword,
                          child: Icon(
                            obscurePassword
                                ? AppLegacyIcons.visibilityOff
                                : AppLegacyIcons.visibilityOn,
                            color: textMuted,
                            size: 20,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onLogin(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _LoginButton(
                        loading: loading,
                        onTap: onLogin,
                      ),
                      const SizedBox(height: 14),

                      // Lupa password
                      Center(
                        child: GestureDetector(
                          onTap: onForgotPassword,
                          child: Text(
                            'Lupa password?',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Info hubungi admin
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: textMuted.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Belum punya akun? Hubungi admin klinik untuk dibuatkan akun.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textMuted,
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Text(
                          '(c) 2026 SinShe Jaya Abadi - All rights reserved',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

class _DesktopBrandingSection extends StatelessWidget {
  const _DesktopBrandingSection({required this.navyColor});

  final Color navyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navyColor,
            AppColors.brandBlueMid,
            AppColors.brandBlueLight,
          ],
        ),
      ),
      child: Column(
        children: const [
          SizedBox(height: 48),
          _BrandingIconBadge(),
          SizedBox(height: 20),
          Text(
            'SinShe Jaya Abadi',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          _BrandingSubtitle(),
          SizedBox(height: 32),
          _FeaturePillsRow(),
          SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _BrandingIconBadge extends StatelessWidget {
  const _BrandingIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        AppLegacyIcons.klinik,
        color: Colors.white,
        size: 48,
      ),
    );
  }
}

class _BrandingSubtitle extends StatelessWidget {
  const _BrandingSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'System Manajemen SinShe Jaya Abadi',
      style: TextStyle(
        fontSize: 15,
        color: Colors.white.withValues(alpha: 0.75),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _FeaturePillsRow extends StatelessWidget {
  const _FeaturePillsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _FeaturePill(icon: AppSymbols.pills, text: 'Manajemen Obat'),
        _FeaturePill(icon: AppSymbols.peopleGroup, text: 'Kelola Pasien'),
        _FeaturePill(icon: AppSymbols.assessment, text: 'Laporan Lengkap'),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.85),
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginWelcomeText extends StatelessWidget {
  const _LoginWelcomeText({
    required this.titleColor,
    required this.subtitleColor,
    this.compact = false,
  });

  final Color titleColor;
  final Color subtitleColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      'Selamat Datang',
      style: TextStyle(
        fontSize: compact ? 20 : 20,
        fontWeight: FontWeight.w800,
        color: titleColor,
        letterSpacing: -0.3,
      ),
    );
    final subtitleWidget = Text(
      'Masuk untuk melanjutkan',
      style: TextStyle(
        fontSize: compact ? 12 : 13,
        color: subtitleColor,
        fontWeight: FontWeight.w500,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleWidget,
          subtitleWidget,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleWidget,
        const SizedBox(height: 4),
        subtitleWidget,
      ],
    );
  }
}

class _LoginFieldLabel extends StatelessWidget {
  const _LoginFieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ctextPrimary(context),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final cardBg = ccardBg(context);
    final dividerColor = cdivider(context);
    final textMuted = ctextMuted(context);
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor, width: 1),
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
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: textMuted, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = cprimary(context);
    return Container(
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
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppSymbols.login, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
