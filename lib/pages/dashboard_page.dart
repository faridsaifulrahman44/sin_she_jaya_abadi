import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app.dart';
import '../core/auth/admin_session.dart';
import '../core/error/app_error_mapper.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_icons.dart';
import '../core/ui/app_legacy_icons.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/transaksi_repository.dart';
import 'laporan_page.dart';
import 'login_page.dart';
import 'obat_hub_page.dart';
import 'pasien_page.dart';
import 'kehadiran_page.dart';
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
    this.onTap,
  });

  final String label;
  final String value;
  final AppHugeIconData icon;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? DarkColors.card : LightColors.card;
    final borderColor = isDark ? DarkColors.borderActive : LightColors.divider;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(14),
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
                          child: HugeIcon(icon: icon, color: color, size: 18),
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
        ),
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
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: clockColor,
            letterSpacing: -0.3,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatDashboardDate(_now),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
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
  final List<List<dynamic>> icon;
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
                      child: HugeIcon(
                        icon: widget.icon,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? DarkColors.surfaceHigh
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
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
            size: 18,
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

  double _penjualanObatHariIni = 0;
  int _jadwalHariIni = 0;
  int _hadirHariIni = 0;
  int _transaksiHariIni = 0;

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
        ]);
        if (mounted) {
          setState(() {
            _penjualanObatHariIni = results[1] as double;
            _jadwalHariIni = results[2] as int;
            _hadirHariIni = results[3] as int;
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

    final obatAccent = cprimary(context);
    final pasienAccent = cteal(context);
    final laporanAccent = cindigo(context);
    final transaksiAccent = cteal(context);

    final role = _role ?? AdminRole.petugas;
    final greeting = role.isOwner ? 'Halo, Owner' : 'Halo, Petugas';
    final canViewReports = role.isOwner;

    // Build menu cards
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
        onTap: () => Navigator.pushNamed(context, PasienPage.routeName),
      ),
    ];

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Kiri: greeting + ringkasan owner ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Greeting + nama klinik
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textOnPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Klinik Sin She Jaya Abadi',
                              style: TextStyle(
                                fontSize: 12,
                                color: textOnPrimary.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Ringkasan owner — di bawah greeting
                        if (role.isOwner) ...[
                          const SizedBox(height: 12),
                          // Row 1: Laporan Hari Ini (hanya label)
                          Row(
                            children: [
                              HugeIcon(
                                icon: AppIcons.laporan,
                                color: textOnPrimary.withValues(alpha: 0.85),
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Laporan Hari Ini',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: textOnPrimary.withValues(alpha: 0.92),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Row 2: Penjualan (dengan nominal)
                          Row(
                            children: [
                              HugeIcon(
                                icon: AppIcons.receipt,
                                color: textOnPrimary.withValues(alpha: 0.65),
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _loadingOwner
                                      ? 'Penjualan : ...'
                                      : 'Penjualan : ${rupiah(_penjualanObatHariIni)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: textOnPrimary.withValues(alpha: 0.68),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ── Kanan: jam + action buttons (bottom right) ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _DashboardClock(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const ThemeToggleBtn(),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _logout(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: textOnPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: HugeIcon(
                                icon: AppIcons.logout,
                                color: textOnPrimary,
                                size: 18,
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
    );
  }

  Widget _buildSummarySection(AdminRole role) {
    if (role.isOwner) {
      // Owner summary sudah di-inline di dalam header biru
      return const SizedBox.shrink();
    } else {
      return _buildAdminSummary();
    }
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
                    value: _loadingAdmin ? '...' : _jadwalHariIni.toString(),
                    icon: AppIcons.jadwalSummary,
                    color: accent3,
                    loading: _loadingAdmin,
                    onTap: () =>
                        Navigator.pushNamed(context, KehadiranPage.routeName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Hadir Hari Ini',
                    value: _loadingAdmin ? '...' : _hadirHariIni.toString(),
                    icon: AppIcons.hadirSummary,
                    color: accent4,
                    loading: _loadingAdmin,
                    onTap: () =>
                        Navigator.pushNamed(context, KehadiranPage.routeName),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DashboardSummaryCard(
                    label: 'Transaksi Hari Ini',
                    value: _loadingAdmin ? '...' : _transaksiHariIni.toString(),
                    icon: AppIcons.receiptSummary,
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
                      icon: AppIcons.jadwalSummary,
                      color: accent3,
                      loading: _loadingAdmin,
                      onTap: () =>
                          Navigator.pushNamed(context, KehadiranPage.routeName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Hadir Hari Ini',
                      value: _loadingAdmin
                          ? '...'
                          : '$_hadirHariIni',
                      icon: AppIcons.hadirSummary,
                      color: accent4,
                      loading: _loadingAdmin,
                      onTap: () =>
                          Navigator.pushNamed(context, KehadiranPage.routeName),
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
                      icon: AppIcons.receiptSummary,
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