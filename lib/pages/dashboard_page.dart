import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../data/repositories/kehadiran_repository.dart';
import '../data/repositories/obat_repository.dart';
import '../data/repositories/transaksi_repository.dart';
import '../features/stok/stok_alert_logic.dart';
import '../widgets/app_bottom_nav.dart';
import 'laporan_page.dart';
import 'obat_hub_page.dart';
import 'transaksi_hub_page.dart';

// ============================================================================
// DASHBOARD CLOCK WIDGET — live clock + date, upper right of app bar
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = DateTime.now();
      setState(() {
        _now = next;
        if (next.day != _lastDate.day) _lastDate = next;
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
          style: AppTextStyles.headlineMd.copyWith(
            color: clockColor,
            letterSpacing: -0.5,
            height: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          formatDashboardDate(_now),
          style: AppTextStyles.caption.copyWith(color: dateColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ============================================================================
// MINI BAR CHART — Stitch performance bar
// ============================================================================
class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  @override
  Widget build(BuildContext context) {
    final primary = cprimary(context);
    // 7 bars: increasing heights with primary gradient
    final heights = [16.0, 24.0, 12.0, 32.0, 40.0, 28.0, 48.0];
    final opacities = [0.2, 0.2, 0.2, 0.4, 0.6, 0.8, 1.0];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (i) => SizedBox(
        width: 8,
        height: heights[i],
        child: Container(
          decoration: BoxDecoration(
            color: primary.withValues(alpha: opacities[i]),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      )),
    );
  }
}

// ============================================================================
// PERFORMA CARD — performance summary with mini bar chart
// ============================================================================
class _PerformaCard extends StatelessWidget {
  const _PerformaCard({required this.omzet});

  final String omzet;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurfaceVariant = isDark ? DarkColors.textSecondary : AppColors.onSurfaceVariant;
    final primary = cprimary(context);
    final success = csuccess(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.surfaceContainerLow : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark
              ? DarkColors.surfaceContainer.withValues(alpha: 0.6)
              : AppColors.surfaceContainerLow,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Performa Hari Ini',
                  style: AppTextStyles.labelLg.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      omzet,
                      style: AppTextStyles.headlineMd.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm10),
                    Text(
                      '+12% vs kemarin',
                      style: AppTextStyles.labelSm.copyWith(
                        color: success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '12 Transaksi Berhasil',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const _MiniBarChart(),
        ],
      ),
    );
  }
}

// ============================================================================
// KPI CARD — compact metric card for dashboard summary
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
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm10),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.caption.copyWith(color: textSecondary),
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
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.sm10),
            Expanded(
              child: Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// QUICK ACTION CARD — for Aksi Cepat grid
// ============================================================================
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.borderColor,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: Container(
          height: 96, // ~h-24
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.bgColor == cprimary(context) ? 0.12 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.title,
                style: AppTextStyles.labelLg.copyWith(color: widget.color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OPERATIONAL ALERT CARD — error/warning alert for dashboard
// ============================================================================
class _OperationalAlertCard extends StatelessWidget {
  const _OperationalAlertCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.titleColor,
    this.subtitleColor,
    this.buttonText,
    this.onButtonTap,
    this.alertType = 'error',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color titleColor;
  final Color? subtitleColor;
  final String? buttonText;
  final VoidCallback? onButtonTap;
  final String alertType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color borderColor;
    Color iconBg;
    Color iconColor;

    if (alertType == 'error') {
      bgColor = isDark
          ? DarkColors.onErrorContainer
          : AppColors.errorContainer;
      borderColor = AppColors.error.withValues(alpha: 0.2);
      iconBg = AppColors.error;
      iconColor = AppColors.onError;
    } else {
      bgColor = const Color(0xFFFFF3E0);
      borderColor = AppColors.warning.withValues(alpha: 0.2);
      iconBg = AppColors.warning;
      iconColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 26),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: subtitleColor ??
                        (isDark ? DarkColors.textSecondary : AppColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          if (buttonText != null && onButtonTap != null) ...[
            SizedBox(
              width: 100,
              height: 36,
              child: ElevatedButton(
                onPressed: onButtonTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: Text(
                  buttonText!,
                  style: AppTextStyles.labelLg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// ACTIVITY ROW — recent transaction activity item
// ============================================================================
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.initials,
    required this.name,
    required this.timeInfo,
    required this.amount,
    required this.status,
  });

  final String initials;
  final String name;
  final String timeInfo;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : AppColors.onSurface;
    final textSecondary = isDark ? DarkColors.textSecondary : AppColors.onSurfaceVariant;
    final primary = cprimary(context);
    final success = csuccess(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? DarkColors.surfaceContainer
                : AppColors.surfaceContainerLow,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.labelLg.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeInfo,
                  style: AppTextStyles.labelSm.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTextStyles.bodyMd.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm10,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.labelSm.copyWith(
                    color: success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
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
  bool _loadingAdmin = false;

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
        setState(() => _role = role);
        _loadSummary(role);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _role = AdminRole.petugas);
        _loadSummary(AdminRole.petugas);
      }
    }
  }

  Future<void> _loadSummary(AdminRole role) async {
    final hariIni = DateTime.now();
    final transaksiRepo = TransaksiRepository();
    final kehadiranRepo = KehadiranRepository();

    if (role.isOwner) {
      try {
        final results = await Future.wait([
          kehadiranRepo.getCountKehadiranByTanggal(hariIni),
          kehadiranRepo.getCountHadirByTanggal(hariIni),
          _fetchStokSummary(),
        ]);
        if (mounted) {
          setState(() {
            _jadwalHariIni = results[0] as int;
            _hadirHariIni = results[1] as int;
            _stokAlertSummary = results[2] as StokAlertSummary;
          });
        }
      } catch (_) {
        // Keep zeros on failure; UI continues to render.
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

  static Future<StokAlertSummary> _fetchStokSummary() async {
    final repo = ObatRepository();
    final obatList = await repo.getObat();
    return buildStokAlertSummary(obatList);
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = (_role ?? AdminRole.petugas).isOwner;
    final greeting = isOwner
        ? 'Selamat Pagi, Owner'
        : 'Halo, Petugas';

    // Owner-only sections
    Widget ownerSection = const SizedBox.shrink();
    if (isOwner) {
      ownerSection = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performa card
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: _PerformaCard(omzet: 'Rp 4.500.000'),
          ),

          // Pusat Kendali Operasional section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pusat Kendali Operasional',
                  style: AppTextStyles.headlineMd.copyWith(
                    color: ctextPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '2 Isu Mendesak',
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error alert
                if (_stokAlertSummary != null &&
                    (_stokAlertSummary!.hasHabis || _stokAlertSummary!.hasMenipis))
                  _OperationalAlertCard(
                    title: '${_stokAlertSummary!.habis.length} Stok Habis',
                    subtitle: 'Herbal Utama & Kapsul Racik',
                    icon: AppSymbols.warning,
                    titleColor: AppColors.onError,
                    buttonText: 'Restock',
                    onButtonTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
                    alertType: 'error',
                  ),
                if (_stokAlertSummary != null && _stokAlertSummary!.hasHabis) ...[
                  const SizedBox(height: AppSpacing.md),
                ],
                // Warning alert (simulated print failure)
                if (_stokAlertSummary != null &&
                    (_stokAlertSummary!.hasMenipis))
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: _OperationalAlertCard(
                      title: '3 Antrean Print Gagal',
                      subtitle: 'Periksa koneksi printer kasir utama',
                      icon: AppSymbols.print,
                      titleColor: AppColors.warning,
                      subtitleColor: AppColors.onSurfaceVariant,
                      alertType: 'warning',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Aksi Cepat section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Aksi Cepat',
              style: AppTextStyles.headlineMd.copyWith(
                color: ctextPrimary(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: [
                _QuickActionCard(
                  title: 'Transaksi Baru',
                  icon: AppSymbols.addCircle,
                  color: AppColors.onError,
                  bgColor: AppColors.primary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    TransaksiHubPage.routeName,
                  ),
                ),
                _QuickActionCard(
                  title: 'Restock Needed',
                  icon: AppSymbols.shoppingCart,
                  color: AppColors.error,
                  bgColor: AppColors.error.withValues(alpha: 0.1),
                  borderColor: AppColors.error.withValues(alpha: 0.2),
                  onTap: () => Navigator.pushNamed(context, ObatHubPage.routeName),
                ),
                _QuickActionCard(
                  title: 'Input Stok',
                  icon: AppSymbols.inventory,
                  color: AppColors.onSurface,
                  bgColor: AppColors.surfaceContainerHigh,
                  borderColor: AppColors.outlineVariant,
                  onTap: () {},
                ),
                _QuickActionCard(
                  title: 'Laporan',
                  icon: AppSymbols.summarize,
                  color: AppColors.onSurface,
                  bgColor: AppColors.surfaceContainerHigh,
                  borderColor: AppColors.outlineVariant,
                  onTap: () => Navigator.pushNamed(context, LaporanPage.routeName),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Aktivitas Terkini section
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
            decoration: BoxDecoration(
              color: isOwner
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? DarkColors.surfaceContainerLowest
                      : AppColors.surfaceContainerLowest)
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.surfaceContainerLow,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.surfaceContainerLow),
                    ),
                    color: AppColors.surfaceBright,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Terkini',
                        style: AppTextStyles.headlineMd.copyWith(
                          color: ctextPrimary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          'Lihat Semua',
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Activity rows (simulated)
                ..._buildActivityRows(context),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      );
    }

    // Admin summary cards
    Widget adminSummary = _buildAdminSummary();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── APP BAR ─────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 64,
              backgroundColor: isOwner
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? DarkColors.inverseSurface
                      : AppColors.surface)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? DarkColors.inverseSurface
                      : AppColors.surface),
              actions: [
                const _DashboardClock(),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          isOwner ? 'O' : 'P',
                          style: AppTextStyles.labelLg.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Klinik Sin She Jaya Abadi',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: cprimary(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── CONTENT ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Welcome section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.headlineLg.copyWith(
                            color: ctextPrimary(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isOwner
                              ? 'Ringkasan operasional hari ini.'
                              : 'Aktivitas klinik hari ini.',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: ctextSecondary(context),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Admin summary
                  if (!isOwner) adminSummary,

                  // Owner section (F0.5 #2 — full Stitch design)
                  ownerSection,

                  // Spacer before bottom nav
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  List<Widget> _buildActivityRows(BuildContext context) {
    return [
      _ActivityRow(
        initials: 'B',
        name: 'Bpk. Budi Santoso',
        timeInfo: '10:45 AM • Tunai • 4 Item',
        amount: 'Rp 850.000',
        status: 'Selesai',
      ),
      _ActivityRow(
        initials: 'S',
        name: 'Ibu Siti Aminah',
        timeInfo: '09:30 AM • QRIS • 2 Item',
        amount: 'Rp 1.200.000',
        status: 'Selesai',
      ),
      _ActivityRow(
        initials: 'A',
        name: 'Anton Wijaya',
        timeInfo: '08:15 AM • Tunai • 1 Item',
        amount: 'Rp 450.000',
        status: 'Selesai',
      ),
    ];
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
          return Column(
            children: [
              Row(
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
                ],
              ),
              const SizedBox(height: AppSpacing.sm10),
              Row(
                children: [
                  Expanded(
                    child: DashboardSummaryCard(
                      label: 'Transaksi Hari Ini',
                      value: _loadingAdmin ? '...' : '$_transaksiHariIni',
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
