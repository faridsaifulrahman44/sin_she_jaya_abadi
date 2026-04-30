import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/ui/app_legacy_icons.dart';
import 'laporan_page.dart';
import 'login_page.dart';
import 'obat_hub_page.dart';
import 'pasien_hub_page.dart';
import 'transaksi_form_page.dart';
import 'transaksi_hub_page.dart';

// ============================================================================
// DASHBOARD MENU CARD — Elegant, Polished Layout
// ============================================================================
class DashboardMenuCard extends StatefulWidget {
  const DashboardMenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<DashboardMenuCard> createState() => _DashboardMenuCardState();
}

class _DashboardMenuCardState extends State<DashboardMenuCard> {
  bool _isHovered = false;

  // ── Color helpers ─────────────────────────────────────────────────────────
  Color get _cardBg => Theme.of(context).colorScheme.surface;

  Color get _cardBorder {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _isHovered
          ? DarkColors.borderActive.withValues(alpha: 0.9)
          : DarkColors.borderActive.withValues(alpha: 0.45);
    }
    return _isHovered
        ? cdivider(context).withValues(alpha: 0.85)
        : cdivider(context).withValues(alpha: 0.55);
  }

  Color get _cardShadow {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _isHovered
          ? DarkColors.shadowLight.withValues(alpha: 0.40)
          : DarkColors.shadowLight.withValues(alpha: 0.20);
    }
    return _isHovered
        ? Colors.black.withValues(alpha: 0.09)
        : Colors.black.withValues(alpha: 0.04);
  }

  Color get _badgeBg {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _isHovered
          ? widget.color.withValues(alpha: 0.16)
          : widget.color.withValues(alpha: 0.10);
    }
    return _isHovered
        ? widget.color.withValues(alpha: 0.18)
        : widget.color.withValues(alpha: 0.10);
  }

  Color get _titleColor {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return _isHovered ? DarkColors.textPrimary : DarkColors.textSecondary;
    }
    return _isHovered
        ? widget.color.withValues(alpha: 1.0)
        : widget.color.withValues(alpha: 0.85);
  }

  // ── Elevation values ───────────────────────────────────────────────────────
  double get _shadowBlur => _isHovered ? 18.0 : 12.0;
  double get _shadowOffsetY => _isHovered ? 6.0 : 3.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _cardBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _cardShadow,
              blurRadius: _shadowBlur,
              offset: Offset(0, _shadowOffsetY),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.color.withValues(alpha: 0.06),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Icon badge ─────────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: widget.icon,
                        color: widget.color,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Title ─────────────────────────────────────────────
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                      letterSpacing: 0.1,
                      height: 1.3,
                    ),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// THEME TOGGLE BUTTON
// ============================================================================
class ThemeToggleBtn extends StatelessWidget {
  const ThemeToggleBtn({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ThemeServiceInstance.notifier.toggle(),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? DarkColors.surfaceHigh
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: isDark
              ? Border.all(color: DarkColors.borderActive, width: 1)
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark ? AppLegacyIcons.lightMode : AppLegacyIcons.darkMode,
            key: ValueKey(isDark),
            color: isDark ? DarkColors.textPrimary : Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD PAGE
// ============================================================================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  AdminRole? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final role = await AdminSession.getRole();
      if (mounted) {
        setState(() {
          _role = role;
        });
      }
    } catch (e) {
      // Default to petugas if role load fails (safer)
      if (mounted) {
        setState(() {
          _role = AdminRole.petugas;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showModernConfirmDialog(
      context: context,
      title: 'Logout',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi?',
      confirmText: 'Logout',
      isDanger: true,
    );
    if (!confirm) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error, stackTrace) {
      if (!context.mounted) return;
      showModernSnackBar(
        context,
        AppErrorMapper.toMessage(error, stackTrace),
        isError: true,
        icon: AppIcons.error,
      );
      return;
    }
    AdminSession.clearCache();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, LoginPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final textOnPrimary = Theme.of(context).colorScheme.onPrimary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = Theme.of(context).colorScheme.onSurface;

    // Accent colors for menu cards
    final obatAccent = cprimary(context);
    final pasienAccent = cteal(context);
    final laporanAccent = cindigo(context);
    final transaksiAccent = cteal(context);

    // Determine role-based greeting and menu visibility
    final role = _role ?? AdminRole.petugas;
    final greeting = role.isOwner ? 'Halo, Owner' : 'Halo, Petugas';
    final canViewReports = role.isOwner;

    // Build menu cards based on role
    final menuCards = <Widget>[
      DashboardMenuCard(
        title: 'Data Obat',
        icon: AppIcons.pills,
        color: obatAccent,
        onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
      ),
      DashboardMenuCard(
        title: 'Pasien',
        icon: AppIcons.pasienHub,
        color: pasienAccent,
        onTap: () => Navigator.pushNamed(context, PasienHubPage.routeName),
      ),
    ];

    // Add Transaksi menu (available for both petugas and owner)
    menuCards.add(
      DashboardMenuCard(
        title: role.isOwner ? 'Transaksi' : 'Tambah Transaksi',
        icon: AppIcons.receipt,
        color: transaksiAccent,
        onTap: () => Navigator.pushNamed(
          context,
          role.isOwner
              ? TransaksiHubPage.routeName
              : TransaksiFormPage.routeName,
        ),
      ),
    );

    // Add Laporan menu only for owner
    if (canViewReports) {
      menuCards.add(
        DashboardMenuCard(
          title: 'Laporan',
          icon: AppIcons.laporan,
          color: laporanAccent,
          onTap: () => Navigator.pushNamed(context, LaporanPage.routeName),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER — clean navy blue, no gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: textOnPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Klinik Sin She Jaya Abadi',
                            style: TextStyle(
                              fontSize: 13,
                              color: textOnPrimary.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const ThemeToggleBtn(),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: textOnPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: HugeIcon(
                                icon: AppIcons.logout,
                                color: textOnPrimary,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MENU GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Menu Utama',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.82,
                        children: menuCards,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
