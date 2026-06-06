import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_legacy_icons.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/obat_repository.dart';
import '../data/repositories/transaksi_repository.dart';
import '../features/stok/stok_alert_logic.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/owner_dashboard_widgets.dart';
import 'laporan_page.dart';
import 'login_page.dart';
import 'obat_hub_page.dart';
import 'pasien_page.dart';
import 'sinkronisasi_stok_page.dart';
import 'transaksi_form_page.dart';
import 'transaksi_hub_page.dart';

// ============================================================================
// SUMMARY CARD WIDGET — compact metric card for dashboard
// ============================================================================
class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.loading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: loading
          ? _buildLoading()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm10),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm10),
                Text(
                  value,
                  style: AppTextStyles.heroMetric.copyWith(
                    color: textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: AppSpacing.sm10),
            Expanded(
              child: Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm10),
        Container(
          height: 24,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// DASHBOARD CLOCK WIDGET — live clock + date, upper right
// ============================================================================
class _DashboardClock extends StatefulWidget {
  const _DashboardClock();

  @override
  State<_DashboardClock> createState() => _DashboardClockState();
}

class _DashboardClockState extends State<_DashboardClock> {
  late Timer _timer;
  late DateTime _now;
  late DateTime _lastDate;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _lastDate = DateTime.now();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = DateTime.now();
      setState(() {
        _now = next;
        // If day changed, rebuild (date label updates automatically)
        if (next.day != _lastDate.day) {
          _lastDate = next;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clockColor = isDark ? DarkColors.textPrimary : Colors.white;
    final dateColor = isDark
        ? DarkColors.textSecondary
        : Colors.white.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatClock(_now),
          style: AppTextStyles.heroJumbo.copyWith(
            color: clockColor,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          formatDashboardDate(_now),
          style: AppTextStyles.caption.copyWith(
            color: dateColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================================
// DASHBOARD MENU CARD — existing elegant card
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<DashboardMenuCard> createState() => _DashboardMenuCardState();
}

class _DashboardMenuCardState extends State<DashboardMenuCard> {
  bool _isHovered = false;

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
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: _cardBorder, width: 1),
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            splashColor: widget.color.withValues(alpha: 0.06),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm10,
                vertical: 18, // no AppSpacing token for 18; keep literal
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
// OBAT STOK BADGE — shown on Data Obat card for owner only
// ============================================================================
class _ObatStokBadge extends StatelessWidget {
  const _ObatStokBadge({required this.summary});

  final StokAlertSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.hasHabis) {
      return _StokAlertPill(
        label: '${summary.habis.length} habis',
        color: cdanger(context),
      );
    }
    if (summary.hasMenipis) {
      return _StokAlertPill(
        label: '${summary.menipis.length} menipis',
        color: cwarning(context),
      );
    }
    return const SizedBox.shrink();
  }

  static Future<StokAlertSummary> _fetchStokSummary() async {
    final repo = ObatRepository();
    final obatList = await repo.getObat();
    return buildStokAlertSummary(obatList);
  }
}

class _StokAlertPill extends StatelessWidget {
  const _StokAlertPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9, // no token; visual pill padding
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(AppSpacing.sm10),
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

  // Summary data
  bool _loadingOwner = false;
  bool _loadingAdmin = false;

  double _omzetHariIni = 0;
  double _penjualanObatHariIni = 0;
  int _jadwalHariIni = 0;
  int _hadirHariIni = 0;
  int _transaksiHariIni = 0;

  // Stok alert badge data (for owner)
  StokAlertSummary? _stokAlertSummary;

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
        _loadSummary(role);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _role = AdminRole.petugas;
        });
        _loadSummary(AdminRole.petugas);
      }
    }
  }

  Future<void> _loadSummary(AdminRole role) async {
    final hariIni = DateTime.now();
    final transaksiRepo = TransaksiRepository();
    final kehadiranRepo = KehadiranRepository();

    if (role.isOwner) {
      setState(() => _loadingOwner = true);
      try {
        final results = await Future.wait([
          transaksiRepo.getTotalTransaksiHariIni(hariIni),
          transaksiRepo.getTotalObatHariIni(hariIni),
          kehadiranRepo.getCountKehadiranByTanggal(hariIni),
          kehadiranRepo.getCountHadirByTanggal(hariIni),
          _ObatStokBadge._fetchStokSummary(),
        ]);
        if (mounted) {
          setState(() {
            _omzetHariIni = results[0] as double;
            _penjualanObatHariIni = results[1] as double;
            _jadwalHariIni = results[2] as int;
            _hadirHariIni = results[3] as int;
            _stokAlertSummary = results[4] as StokAlertSummary;
            _loadingOwner = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingOwner = false);
      }
    } else {
      setState(() => _loadingAdmin = true);
      try {
        final results = await Future.wait([
          kehadiranRepo.getCountKehadiranByTanggal(hariIni),
          kehadiranRepo.getCountHadirByTanggal(hariIni),
          transaksiRepo.getCountTransaksiHariIni(hariIni),
        ]);
        if (mounted) {
          setState(() {
            _jadwalHariIni = results[0];
            _hadirHariIni = results[1];
            _transaksiHariIni = results[2];
            _loadingAdmin = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingAdmin = false);
      }
    }
  }

  List<QuickActionData> _buildQuickActions(BuildContext context, AdminRole role) {
    final actions = <QuickActionData>[
      QuickActionData(
        title: 'Tambah Obat',
        subtitle: 'Master & stok',
        icon: AppSymbols.pills,
        color: cprimary(context),
        onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
      ),
      QuickActionData(
        title: 'Input Transaksi',
        subtitle: role.isOwner ? 'Obat & Praktek' : 'Transaksi baru',
        icon: AppSymbols.receipt,
        color: cteal(context),
        onTap: () => Navigator.pushNamed(
          context,
          role.isOwner ? TransaksiHubPage.routeName : TransaksiFormPage.routeName,
        ),
      ),
    ];
    if (role.isOwner) {
      actions.add(
        QuickActionData(
          title: 'Lihat Laporan',
          subtitle: 'Harian / Bulanan / Tahunan',
          icon: AppSymbols.laporan,
          color: cindigo(context),
          onTap: () => Navigator.pushNamed(context, LaporanPage.routeName),
        ),
      );
      actions.add(
        QuickActionData(
          title: 'Sinkronisasi Stok',
          subtitle: 'Audit & koreksi',
          icon: AppSymbols.refresh,
          color: cobatAmber(context),
          onTap: () => Navigator.pushNamed(context, SinkronisasiStokPage.routeName),
        ),
      );
    }
    return actions;
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

    final obatAccent = cprimary(context);
    final pasienAccent = cteal(context);
    final laporanAccent = cindigo(context);
    final transaksiAccent = cteal(context);

    final role = _role ?? AdminRole.petugas;
    final greeting = role.isOwner ? 'Halo, Owner' : 'Halo, Petugas';
    final canViewReports = role.isOwner;

    // Build menu cards
    Widget obatCard = DashboardMenuCard(
      title: 'Data Obat',
      icon: AppSymbols.pills,
      color: obatAccent,
      onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
    );

    // Owner badge on Data Obat card — outside the shadow boundary
    if (role.isOwner) {
      obatCard = Stack(
        clipBehavior: Clip.none,
        children: [
          obatCard,
          if (_stokAlertSummary != null &&
              (_stokAlertSummary!.hasHabis ||
                  _stokAlertSummary!.hasMenipis))
            Positioned(
              top: -4,
              right: -4,
              child: _ObatStokBadge(summary: _stokAlertSummary!),
            ),
        ],
      );
    }

    final menuCards = <Widget>[
      obatCard,
      DashboardMenuCard(
        title: 'Pasien',
        icon: AppSymbols.pasienHub,
        color: pasienAccent,
        onTap: () => Navigator.pushNamed(context, PasienPage.routeName),
      ),
    ];

    menuCards.add(
      DashboardMenuCard(
        title: role.isOwner ? 'Transaksi' : 'Tambah Transaksi',
        icon: AppSymbols.receipt,
        color: transaksiAccent,
        onTap: () => Navigator.pushNamed(
          context,
          role.isOwner
              ? TransaksiHubPage.routeName
              : TransaksiFormPage.routeName,
        ),
      ),
    );

    if (canViewReports) {
      menuCards.add(
        DashboardMenuCard(
          title: 'Laporan',
          icon: AppSymbols.laporan,
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
            // ── HEADER ──────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: AppColors.headerBlueDark,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.headerBlueDark.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: title left, clock+date right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: greeting + clinic name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppTextStyles.headlineLg.copyWith(
                                fontWeight: FontWeight.w800,
                                color: textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Klinik Sin She Jaya Abadi',
                              style: TextStyle(
                                fontSize: 13,
                                color: textOnPrimary.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (role.isOwner) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Text(
                                    'Laporan Hari Ini:  ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textOnPrimary.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Penjualan : ${_loadingOwner ? '...' : rupiah(_omzetHariIni)}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: textOnPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Right: clock + date
                      const _DashboardClock(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Subtitle row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          role.isOwner
                              ? 'Ringkasan aktivitas klinik hari ini'
                              : 'Aktivitas klinik hari ini',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textOnPrimary.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Action buttons (theme + logout)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ThemeToggleBtn(),
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm10),
                              decoration: BoxDecoration(
                                color: textOnPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                AppSymbols.logout,
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

            // ── SUMMARY CARDS ─────────────────────────────────────────────
            _buildSummarySection(role),

            // ── OWNER ENHANCEMENTS (F12.2) ───────────────────────────────
            if (role.isOwner) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuickActionGrid(
                      actions: _buildQuickActions(context, role),
                    ),
                    const SizedBox(height: AppSpacing.md14),
                    const SalesChart7dCard(),
                    const SizedBox(height: AppSpacing.md),
                    const StokKritisCard(),
                    const SizedBox(height: AppSpacing.md),
                    const TopObat7dCard(),
                  ],
                ),
              ),
            ],

            // ── MENU GRID ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu Utama',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md14),
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildSummarySection(AdminRole role) {
    if (role.isOwner) {
      return _buildOwnerSummary();
    } else {
      return _buildAdminSummary();
    }
  }

  Widget _buildOwnerSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.surface : AppColors.surface;
    final accent1 = cprimary(context);       // blue for omzet
    final accent2 = cobatAmber(context);     // amber for penjualan obat
    final accent3 = cteal(context);          // teal for jadwal
    final accent4 = csuccess(context);        // green for hadir

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md14,
        AppSpacing.lg,
        AppSpacing.xs6,
      ),
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 2-column grid for wider screens, 1-column for narrow
          if (constraints.maxWidth >= 500) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DashboardSummaryCard(
                        label: 'Omzet Hari Ini',
                        value: _loadingOwner ? '...' : rupiah(_omzetHariIni),
                        icon: AppSymbols.wallet,
                        color: accent1,
                        loading: _loadingOwner,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm10),
                    Expanded(
                      child: DashboardSummaryCard(
                        label: 'Penjualan Obat Hari Ini',
                        value: _loadingOwner ? '...' : rupiah(_penjualanObatHariIni),
                        icon: AppSymbols.pills,
                        color: accent2,
                        loading: _loadingOwner,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm10),
                Row(
                  children: [
                    Expanded(
                      child: DashboardSummaryCard(
                        label: 'Jadwal Hari Ini',
                        value: _loadingOwner ? '...' : '$_jadwalHariIni',
                        icon: AppSymbols.jadwalSummary,
                        color: accent3,
                        loading: _loadingOwner,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm10),
                    Expanded(
                      child: DashboardSummaryCard(
                        label: 'Hadir Hari Ini',
                        value: _loadingOwner ? '...' : '$_hadirHariIni',
                        icon: AppSymbols.hadirSummary,
                        color: accent4,
                        loading: _loadingOwner,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs6),
              ],
            );
          }
          // Narrow / 1-column
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Omzet Hari Ini',
                      value: _loadingOwner
                          ? '...'
                          : rupiah(_omzetHariIni),
                      icon: AppSymbols.wallet,
                      color: accent1,
                      loading: _loadingOwner,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm10),
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Penjualan Obat Hari Ini',
                      value: _loadingOwner
                          ? '...'
                          : rupiah(_penjualanObatHariIni),
                      icon: AppSymbols.pills,
                      color: accent2,
                      loading: _loadingOwner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm10),
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Jadwal Hari Ini',
                      value: _loadingOwner
                          ? '...'
                          : '$_jadwalHariIni',
                      icon: AppSymbols.jadwalSummary,
                      color: accent3,
                      loading: _loadingOwner,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm10),
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Hadir Hari Ini',
                      value: _loadingOwner
                          ? '...'
                          : '$_hadirHariIni',
                      icon: AppSymbols.hadirSummary,
                      color: accent4,
                      loading: _loadingOwner,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.surface : AppColors.surface;
    final accent3 = cteal(context);
    final accent4 = csuccess(context);
    final accent5 = cprimary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md14,
        AppSpacing.lg,
        AppSpacing.xs6,
      ),
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 500) {
            return Row(
              children: [
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Jadwal Hari Ini',
                    value: _loadingAdmin ? '...' : '$_jadwalHariIni',
                    icon: AppSymbols.jadwalSummary,
                    color: accent3,
                    loading: _loadingAdmin,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm10),
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Hadir Hari Ini',
                    value: _loadingAdmin ? '...' : '$_hadirHariIni',
                    icon: AppSymbols.hadirSummary,
                    color: accent4,
                    loading: _loadingAdmin,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm10),
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Transaksi Hari Ini',
                    value: _loadingAdmin ? '...' : '$_transaksiHariIni',
                    icon: AppSymbols.receiptSummary,
                    color: accent5,
                    loading: _loadingAdmin,
                  ),
                ),
              ],
            );
          }
          // Narrow / 1-column: wrap in 2 cols
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Jadwal Hari Ini',
                      value: _loadingAdmin
                          ? '...'
                          : '$_jadwalHariIni',
                      icon: AppSymbols.jadwalSummary,
                      color: accent3,
                      loading: _loadingAdmin,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm10),
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Hadir Hari Ini',
                      value: _loadingAdmin
                          ? '...'
                          : '$_hadirHariIni',
                      icon: AppSymbols.hadirSummary,
                      color: accent4,
                      loading: _loadingAdmin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm10),
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Transaksi Hari Ini',
                      value: _loadingAdmin
                          ? '...'
                          : '$_transaksiHariIni',
                      icon: AppSymbols.receiptSummary,
                      color: accent5,
                      loading: _loadingAdmin,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm10),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: AppSpacing.xs6),
            ],
          );
        },
      ),
    );
  }
}

// NOTE: Owner-only widget implementations (SalesChart7dCard, StokKritisCard,
// TopObat7dCard, QuickActionGrid) live in:
//   lib/widgets/owner_dashboard_widgets.dart
// They are imported and instantiated from the build() method of DashboardPage.
