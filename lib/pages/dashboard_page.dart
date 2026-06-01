import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
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
import '../core/utils/obat_foto_resolver.dart';
import '../data/models/obat_model.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/obat_repository.dart';
import '../data/repositories/transaksi_repository.dart';
import '../features/stok/stok_alert_logic.dart';
import '../widgets/app_bottom_nav.dart';
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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
            const SizedBox(width: 10),
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
        const SizedBox(height: 10),
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: clockColor,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatDashboardDate(_now),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
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
          borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            splashColor: widget.color.withValues(alpha: 0.06),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
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
                  const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
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

  List<QuickActionItem> _buildQuickActions(BuildContext context, AdminRole role) {
    final actions = <QuickActionItem>[
      QuickActionItem(
        icon: AppSymbols.pills,
        label: 'Tambah Obat',
        color: cprimary(context),
        onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
      ),
      QuickActionItem(
        icon: AppSymbols.receipt,
        label: 'Input Transaksi',
        color: cteal(context),
        onTap: () => Navigator.pushNamed(
          context,
          role.isOwner ? TransaksiHubPage.routeName : TransaksiFormPage.routeName,
        ),
      ),
    ];
    if (role.isOwner) {
      actions.add(
        QuickActionItem(
          icon: AppSymbols.laporan,
          label: 'Lihat Laporan',
          color: cindigo(context),
          onTap: () => Navigator.pushNamed(context, LaporanPage.routeName),
        ),
      );
      actions.add(
        QuickActionItem(
          icon: AppSymbols.refresh,
          label: 'Sinkronisasi Stok',
          color: cobatAmber(context),
          onTap: () => Navigator.pushNamed(context, '/sinkronisasi-stok'),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SinShe Jaya Abadi',
                              style: TextStyle(
                                fontSize: 13,
                                color: textOnPrimary.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: clock + date
                      const _DashboardClock(),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuickActionGrid(
                      actions: _buildQuickActions(context, role),
                    ),
                    const SizedBox(height: 14),
                    const SalesChart7dCard(),
                    const SizedBox(height: 12),
                    const StokKritisCard(),
                    const SizedBox(height: 12),
                    const TopObat7dCard(),
                  ],
                ),
              ),
            ],

            // ── MENU GRID ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
    final bgColor = isDark ? DarkColors.surface : const Color(0xFFF1F5F9);
    final accent1 = cprimary(context);       // blue for omzet
    final accent2 = cobatAmber(context);     // amber for penjualan obat
    final accent3 = cteal(context);          // teal for jadwal
    final accent4 = csuccess(context);        // green for hadir

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
                    const SizedBox(width: 10),
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
                const SizedBox(height: 10),
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
                    const SizedBox(width: 10),
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
                const SizedBox(height: 6),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.surface : const Color(0xFFF1F5F9);
    final accent3 = cteal(context);
    final accent4 = csuccess(context);
    final accent5 = cprimary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Hadir Hari Ini',
                    value: _loadingAdmin ? '...' : '$_hadirHariIni',
                    icon: AppSymbols.hadirSummary,
                    color: accent4,
                    loading: _loadingAdmin,
                  ),
                ),
                const SizedBox(width: 10),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// SALES CHART CARD — 7-day line chart (owner only)
// ============================================================================
class _SalesDataPoint {
  const _SalesDataPoint(this.dayLabel, this.total);
  final String dayLabel;
  final double total;
}

class _SalesChartCard extends StatefulWidget {
  const _SalesChartCard({super.key});

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  late Future<List<_SalesDataPoint>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_SalesDataPoint>> _load() async {
    final repo = TransaksiRepository();
    final raw = await repo.getDailySalesLast7Days();
    // Build 7-day window ending today
    final today = DateTime.now();
    final List<_SalesDataPoint> result = [];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final value = raw[key] ?? 0.0;
      result.add(_SalesDataPoint(_dayLabel(d), value));
    }
    return result;
  }

  String _dayLabel(DateTime d) {
    const names = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return '${names[d.weekday % 7]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final accent = cprimary(context);

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Penjualan 7 Hari',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: FutureBuilder<List<_SalesDataPoint>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: accent,
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Gagal memuat chart',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  );
                }
                final data = snap.data ?? const [];
                return _buildChart(context, data, accent, textPrimary, textSecondary, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<_SalesDataPoint> data,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text('Belum ada data', style: TextStyle(fontSize: 12, color: textSecondary)),
      );
    }
    final maxY = data.map((d) => d.total).fold<double>(0, (a, b) => a > b ? a : b);
    final chartMaxY = maxY == 0 ? 100000.0 : maxY * 1.2;
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].total),
    ];
    final gridColor = isDark
        ? DarkColors.borderActive.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: chartMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
          horizontalInterval: chartMaxY / 3,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: chartMaxY / 3,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _shortRupiah(value),
                    style: TextStyle(fontSize: 9, color: textSecondary),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    data[i].dayLabel,
                    style: TextStyle(fontSize: 9, color: textSecondary),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark
                ? DarkColors.surfaceHigh
                : Colors.white.withValues(alpha: 0.96),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final idx = spot.x.toInt();
                final label = idx >= 0 && idx < data.length ? data[idx].dayLabel : '';
                return LineTooltipItem(
                  '$label\n${rupiah(spot.y)}',
                  TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            color: accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: accent,
                  strokeColor: isDark ? DarkColors.card : Colors.white,
                  strokeWidth: 1.5,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.28),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortRupiah(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toStringAsFixed(0);
  }
}

// ============================================================================
// STOK KRITIS LIST — owner only
// ============================================================================
class _StokKritisCard extends StatefulWidget {
  const _StokKritisCard({super.key});

  @override
  State<_StokKritisCard> createState() => _StokKritisCardState();
}

class _StokKritisCardState extends State<_StokKritisCard> {
  late Future<List<ObatModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ObatModel>> _load() async {
    final repo = ObatRepository();
    return repo.getStokMenipis(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final accent = cdanger(context);

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Stok Kritis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<ObatModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: accent,
                      ),
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Gagal memuat stok',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                );
              }
              final data = snap.data ?? const <ObatModel>[];
              if (data.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: csuccess(context), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tidak ada stok kritis',
                        style: TextStyle(fontSize: 12.5, color: textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < data.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: borderColor.withValues(alpha: 0.35),
                      ),
                    _StokKritisRow(obat: data[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StokKritisRow extends StatelessWidget {
  const _StokKritisRow({required this.obat});
  final ObatModel obat;

  Color _statusColor(BuildContext context) {
    if (obat.stok <= 0) return cdanger(context);
    if (obat.stok <= (obat.stokMinimum / 2).ceil()) return cdanger(context);
    return cwarning(context);
  }

  String _statusLabel() {
    if (obat.stok <= 0) return 'Habis';
    return 'Menipis';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final statusColor = _statusColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                Icons.medication_outlined,
                color: statusColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  obat.nama,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok ${obat.stok}  ·  Min ${obat.stokMinimum}',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TOP 5 OBAT — owner only
// ============================================================================
class _TopObatCard extends StatefulWidget {
  const _TopObatCard({super.key});

  @override
  State<_TopObatCard> createState() => _TopObatCardState();
}

class _TopObatCardState extends State<_TopObatCard> {
  late Future<List<TopObatItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TopObatItem>> _load() async {
    final repo = TransaksiRepository();
    return repo.getTopObatByPeriod(days: 7, limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final accent = cobatAmber(context);

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Top 5 Obat · 7 Hari',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<TopObatItem>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: accent,
                      ),
                    ),
                  ),
                );
              }
              if (snap.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Gagal memuat data',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                );
              }
              final data = snap.data ?? const <TopObatItem>[];
              if (data.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Belum ada penjualan minggu ini',
                    style: TextStyle(fontSize: 12.5, color: textSecondary),
                  ),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < data.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        color: borderColor.withValues(alpha: 0.35),
                      ),
                    _TopObatRow(item: data[i], rank: i + 1),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopObatRow extends StatelessWidget {
  const _TopObatRow({required this.item, required this.rank});
  final TopObatItem item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final accent = cobatAmber(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Foto
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 36,
              height: 36,
              child: _ObatThumb(fotoKey: item.fotoKey),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.nama,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.totalQty} terjual',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rupiah(item.totalNominal),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ObatThumb extends StatelessWidget {
  const _ObatThumb({required this.fotoKey});
  final String? fotoKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark
        ? DarkColors.surfaceHigh
        : const Color(0xFFE2E8F0);
    if (fotoKey == null || fotoKey!.isEmpty) {
      return Container(
        color: placeholderBg,
        child: Icon(
          Icons.medication_outlined,
          size: 18,
          color: isDark ? DarkColors.textSecondary : const Color(0xFF94A3B8),
        ),
      );
    }
    final url = ObatFotoResolver.resolveStorageUrl(fotoKey!);
    if (url == null) {
      return Container(
        color: placeholderBg,
        child: Icon(
          Icons.medication_outlined,
          size: 18,
          color: isDark ? DarkColors.textSecondary : const Color(0xFF94A3B8),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: placeholderBg,
        child: Icon(
          Icons.medication_outlined,
          size: 18,
          color: isDark ? DarkColors.textSecondary : const Color(0xFF94A3B8),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: placeholderBg);
      },
    );
  }
}

// ============================================================================
// QUICK ACTION CARD — tactile 2x2 grid (owner only)
// ============================================================================
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pressDown() => _ctrl.forward();
  void _pressUp() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;

    return GestureDetector(
      onTapDown: (_) => _pressDown(),
      onTapUp: (_) => _pressUp(),
      onTapCancel: _pressUp,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(widget.icon, color: widget.color, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.role});
  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    final actions = <Widget>[
      _QuickActionCard(
        label: 'Tambah Obat',
        icon: Icons.add_box_outlined,
        color: cprimary(context),
        onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
      ),
      _QuickActionCard(
        label: 'Input Transaksi',
        icon: Icons.receipt_long_outlined,
        color: cteal(context),
        onTap: () => Navigator.pushNamed(context, TransaksiFormPage.routeName),
      ),
    ];

    if (role.isOwner) {
      actions.addAll([
        _QuickActionCard(
          label: 'Lihat Laporan',
          icon: Icons.analytics_outlined,
          color: cindigo(context),
          onTap: () => Navigator.pushNamed(context, LaporanPage.routeName),
        ),
        _QuickActionCard(
          label: 'Sinkronisasi Stok',
          icon: Icons.sync_outlined,
          color: cobatAmber(context),
          onTap: () => Navigator.pushNamed(context, SinkronisasiStokPage.routeName),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Aksi Cepat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: actions,
        ),
      ],
    );
  }
}