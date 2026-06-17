import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/auth/admin_session.dart';
import '../core/design_system/app_tokens.dart';
import '../core/design_system/emil_design.dart';
import '../core/theme/app_theme.dart';
import '../core/ui/app_symbols.dart';
import '../core/utils/formatters.dart';
import '../core/utils/obat_foto_resolver.dart';
import '../data/models/obat_model.dart';
import '../data/models/top_obat_item.dart';
import '../data/repositories/obat_repository.dart';
import '../data/repositories/transaksi_repository.dart';

// ============================================================================
// F12.2 — Owner Dashboard Enhancement Widgets
//
// Distinctive production-grade widgets for owner-only dashboard:
//   - SalesChart7dCard         (fl_chart BarChart, 7 days)
//   - StokKritisCard           (low stock list with status colors)
//   - TopObat7dCard            (top 5 obat minggu ini, with thumbnails)
//   - QuickActionGrid          (4 quick-action cards with press feedback)
//
// All widgets are gated by [AdminRole.isOwner] in the parent DashboardPage.
// Aesthetic direction: refined medical-grade bento layout — generous spacing,
// tight typography, hairline borders, deep teal accent, warm amber for
// warnings, no decorative noise. Inspired by Apple Health + Linear trends.
// ============================================================================

// ─── Shared: Section Header ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final accentColor = iconColor ?? cteal(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                  height: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared: Card surface ──────────────────────────────────────────────────

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = cisDark(context);
    final bg = ccardBg(context);
    final borderColor = isDark
        ? DarkColors.borderActive.withValues(alpha: 0.45)
        : cdivider(context).withValues(alpha: 0.55);
    final shadow = isDark
        ? Colors.black.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

// ============================================================================
// 1. SALES CHART — 7 Days
// ============================================================================

class SalesChart7dCard extends StatelessWidget {
  const SalesChart7dCard({super.key, this.transaksiRepo});

  final TransaksiRepository? transaksiRepo;

  @override
  Widget build(BuildContext context) {
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);

    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Penjualan 7 Hari',
            subtitle: 'Tren nominal harian',
            icon: AppSymbols.trendingUp,
            iconColor: cteal(context),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<Map<DateTime, double>>(
            future: (transaksiRepo ?? TransaksiRepository())
                .getDailySalesByRange(7),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ChartSkeleton();
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Gagal memuat grafik',
                  detail: snapshot.error.toString(),
                );
              }
              final data = snapshot.data ?? const <DateTime, double>{};
              return _SalesBarChart(
                data: data,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({
    required this.data,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Map<DateTime, double> data;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _EmptyChart(textSecondary: textSecondary);
    }

    // Sort ascending by date
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxY = entries
            .map((e) => e.value)
            .fold<double>(0, (acc, v) => v > acc ? v : acc) *
        1.25;
    final safeMax = maxY <= 0 ? 100.0 : maxY;

    final accent = cteal(context);
    final mutedAxis = ctextMuted(context).withValues(alpha: 0.4);

    // Format label "Sen" "Sel" (3 huruf nama hari)
    final dayLabels = entries
        .map((e) => DateFormat('EEE', 'id_ID').format(e.key).substring(0, 3))
        .toList();

    // Format tooltip
    final dateLabels = entries
        .map((e) => DateFormat('d MMM', 'id_ID').format(e.key))
        .toList();

    // For axis label, use 1.5k format
    String compactCurrency(num v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
      return v.toStringAsFixed(0);
    }

    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              rupiah(total),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
                fontFeatures: const [FontFeature.tabularFigures()],
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                'total 7 hari',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 140,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMax,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      cisDark(context)
                          ? DarkColors.surfaceHigh
                          : ctextPrimary(context),
                  tooltipRoundedRadius: 10,
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  getTooltipItem: (group, _, rod, __) {
                    final i = group.x;
                    return BarTooltipItem(
                      '${dateLabels[i]}\n',
                      TextStyle(
                        color: cisDark(context)
                            ? ctextPrimary(context)
                            : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.5,
                      ),
                      children: [
                        TextSpan(
                          text: rupiah(rod.toY),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= dayLabels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dayLabels[i],
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, _) {
                      if (value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          compactCurrency(value),
                          style: TextStyle(
                            color: textSecondary.withValues(alpha: 0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: mutedAxis,
                  strokeWidth: 1,
                  dashArray: const [3, 4],
                ),
                horizontalInterval: safeMax / 3,
              ),
              barGroups: entries.asMap().entries.map((entry) {
                final idx = entry.key;
                final value = entry.value.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: accent,
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: safeMax,
                        color: accent.withValues(alpha: 0.07),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            duration: EmilDesign.normal,
            curve: EmilDesign.enter,
          ),
        ),
      ],
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();
  @override
  Widget build(BuildContext context) {
    final shimmer = cshimmer(context);
    return SizedBox(
      height: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 24,
            width: 120,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final h = 30.0 + (i * 8.0);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.textSecondary});
  final Color textSecondary;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppSymbols.chartBar,
              size: 28,
              color: textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. STOK KRITIS — Top Low-Stock Items
// ============================================================================

class StokKritisCard extends StatelessWidget {
  const StokKritisCard({super.key, this.obatRepo, this.limit = 5});

  final ObatRepository? obatRepo;
  final int limit;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Stok Kritis',
            subtitle: 'Obat yang perlu restock',
            icon: AppSymbols.warning,
            iconColor: cwarning(context),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<ObatModel>>(
            future: (obatRepo ?? ObatRepository())
                .getStokMenipis(limit: limit),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ListSkeleton(itemCount: 3, itemHeight: 48);
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Gagal memuat stok',
                  detail: snapshot.error.toString(),
                );
              }
              final items = snapshot.data ?? const <ObatModel>[];
              if (items.isEmpty) {
                return _StokAmanState();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _StokKritisRow(
                      item: items[i],
                      isFirst: i == 0,
                      isLast: i == items.length - 1,
                    ),
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
  const _StokKritisRow({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  final ObatModel item;
  final bool isFirst;
  final bool isLast;

  Color _statusColor(BuildContext context) {
    if (item.isStokHabis) return cdanger(context);
    return cwarning(context);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final isDark = cisDark(context);

    final statusBg = statusColor.withValues(alpha: isDark ? 0.18 : 0.12);
    final statusLabel = item.isStokHabis ? 'HABIS' : 'MENIPIS';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: isDark
                      ? DarkColors.borderActive.withValues(alpha: 0.20)
                      : cdivider(context).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Status indicator pill
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Name + min
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.namaObat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Min: ${item.stokMinimum} ${item.satuan ?? ''}'.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Stok + status badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${item.stokSaatIni}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
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

class _StokAmanState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textSecondary = ctextSecondary(context);
    final accent = csuccess(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              AppSymbols.checkCircle,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Stok Aman',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tidak ada obat dengan stok kritis',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. TOP 5 OBAT MINGGU INI
// ============================================================================

class TopObat7dCard extends StatelessWidget {
  const TopObat7dCard({super.key, this.transaksiRepo, this.obatRepo});

  final TransaksiRepository? transaksiRepo;
  final ObatRepository? obatRepo;

  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionHeader(
            title: 'Top 5 Obat',
            subtitle: '7 hari terakhir',
            icon: AppSymbols.star,
            iconColor: cobatAmber(context),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<TopObatItem>>(
            future: (transaksiRepo ?? TransaksiRepository())
                .getTopObatByPeriod(days: 7, limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ListSkeleton(itemCount: 5, itemHeight: 56);
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Gagal memuat top obat',
                  detail: snapshot.error.toString(),
                );
              }
              final items = snapshot.data ?? const <TopObatItem>[];
              if (items.isEmpty) {
                return _TopObatEmptyState();
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    _TopObatRow(item: items[i]),
                    if (i < items.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: cisDark(context)
                            ? DarkColors.borderActive.withValues(alpha: 0.20)
                            : cdivider(context).withValues(alpha: 0.4),
                      ),
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
  const _TopObatRow({required this.item});

  final TopObatItem item;

  Color _rankColor(BuildContext context) {
    switch (item.rankType) {
      case 'gold':
        return const Color(0xFFD4A437);
      case 'silver':
        return const Color(0xFF9AA0A6);
      case 'bronze':
        return const Color(0xFFB87333);
      default:
        return ctextMuted(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final rankColor = _rankColor(context);
    final accent = cteal(context);
    final isDark = cisDark(context);
    final placeholderBg = isDark
        ? DarkColors.surfaceHigh
        : const Color(0xFFF1F5F9);

    final fotoUri = ObatFotoResolver.resolveStorageUrl(
      fotoKey: item.fotoKey,
      fotoUpdatedAt: item.fotoUpdatedAt,
      fotoUrl: item.fotoUrl,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Rank chip
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.rank}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: rankColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: placeholderBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? DarkColors.borderActive.withValues(alpha: 0.30)
                    : cdivider(context).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: fotoUri != null
                ? Image.network(
                    fotoUri.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FotoPlaceholder(),
                    loadingBuilder: (_, child, p) {
                      if (p == null) return child;
                      return _FotoPlaceholder();
                    },
                  )
                : _FotoPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Name + sold
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.namaObat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.jumlahTerjual} terjual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Nominal
          Text(
            rupiah(item.totalNominal),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        AppSymbols.medication,
        size: 18,
        color: ctextMuted(context).withValues(alpha: 0.6),
      ),
    );
  }
}

class _TopObatEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textSecondary = ctextSecondary(context);
    final accent = ctextMuted(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(AppSymbols.inbox, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Belum Ada Penjualan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: ctextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '7 hari terakhir belum ada transaksi obat',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. QUICK ACTION CARDS — 2x2 Grid
// ============================================================================

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(
          title: 'Aksi Cepat',
          subtitle: 'Operasional yang sering dipakai',
          icon: AppSymbols.bolt,
          iconColor: cprimary(context),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cols = w >= 360 ? 2 : 1;
            final cardW = cols == 2 ? (w - AppSpacing.md) / 2 : w;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: actions
                  .map((a) => SizedBox(
                        width: cardW,
                        child: _QuickActionCard(data: a),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class QuickActionData {
  const QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.data});
  final QuickActionData data;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  void _onPressStart(_) {
    if (!mounted) return;
    setState(() => _pressed = true);
  }

  void _onPressEnd(_) {
    if (!mounted) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = cisDark(context);
    final cardBg = ccardBg(context);
    final border = _pressed
        ? widget.data.color.withValues(alpha: 0.55)
        : (isDark
            ? DarkColors.borderActive.withValues(alpha: 0.45)
            : cdivider(context).withValues(alpha: 0.55));

    final textPrimary = ctextPrimary(context);
    final textSecondary = ctextSecondary(context);
    final iconBg = _pressed
        ? widget.data.color.withValues(alpha: isDark ? 0.22 : 0.20)
        : widget.data.color.withValues(alpha: isDark ? 0.14 : 0.12);

    return GestureDetector(
      onTapDown: _onPressStart,
      onTapUp: _onPressEnd,
      onTapCancel: () => _onPressEnd(null),
      onTap: widget.data.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? EmilDesign.pressScale : 1.0,
        duration: EmilDesign.fast,
        curve: EmilDesign.gesture,
        child: AnimatedContainer(
          duration: EmilDesign.fast,
          curve: EmilDesign.gesture,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: _pressed ? 0.08 : 0.04),
                blurRadius: _pressed ? 16 : 8,
                offset: Offset(0, _pressed ? 6 : 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: EmilDesign.fast,
                curve: EmilDesign.gesture,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  widget.data.icon,
                  color: widget.data.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.data.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Shared utility widgets
// ============================================================================

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.itemCount, required this.itemHeight});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final shimmer = cshimmer(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 9,
                      width: 80,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.detail});
  final String message;
  final String detail;
  @override
  Widget build(BuildContext context) {
    final textSecondary = ctextSecondary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            AppSymbols.error,
            color: cdanger(context),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight role check wrapper — returns child only when AdminRole.isOwner.
/// Use to gate owner-only widgets.
class OwnerOnly extends StatelessWidget {
  const OwnerOnly({super.key, required this.child, required this.role});
  final Widget child;
  final AdminRole role;

  @override
  Widget build(BuildContext context) {
    if (!role.isOwner) return const SizedBox.shrink();
    return child;
  }
}
