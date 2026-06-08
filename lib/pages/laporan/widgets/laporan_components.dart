// F0.5 #8: Redesigned per Stitch KEEP #13 (laporan_eksekutif_owner).
// OWNER-ONLY executive report — period chips + Bento KPI grid + sparkline +
// doughnut distribution + Top 5 obat. All values use AppTokens.
import 'package:flutter/material.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/laporan/daily_income_point.dart' show DailyIncomePoint;

// ── Loading box (skeleton) ───────────────────────────────────────────────────
class LaporanLoadingBox extends StatelessWidget {
  const LaporanLoadingBox({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

// ── Period chip (Stitch: Hari Ini / 7H / 30H, rounded-full) ─────────────────
class LaporanFilterChip extends StatelessWidget {
  const LaporanFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final teal = cprimaryStitch(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm10,
        ),
        decoration: BoxDecoration(
          color: selected ? teal : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? teal : coutlineVariantStitch(context),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLg.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Insight callout (Stitch: solid teal #006565 rounded-xl) ────────────────
class LaporanInsightCard extends StatelessWidget {
  const LaporanInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isSuccess = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final teal = cprimaryStitch(context);
    // Per Stitch visual contract: solid teal callout. `isSuccess` swaps to a
    // softer positive accent only when the delta is meaningfully upward.
    final bg = isSuccess ? AppColors.positive : teal;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.size16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headlineMd.copyWith(
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
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

// ── Summary card (KPI) — surface-container bg, AppTextStyles tokens ─────────
class LaporanSummaryCard extends StatelessWidget {
  const LaporanSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final teal = cprimaryStitch(context);
    final acc = accentColor ?? teal;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: coutlineVariantStitch(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm10),
            decoration: BoxDecoration(
              color: acc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg14),
            ),
            child: Icon(icon, color: acc, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.headlineLg.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card — surface-container bg, AppRadius.lg (16) ──────────────────
class LaporanSectionCard extends StatelessWidget {
  const LaporanSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: coutlineVariantStitch(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// ── Section header — title + optional trailing link ──────────────────────────
class LaporanSectionHeader extends StatelessWidget {
  const LaporanSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.headline.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Sparkline (line + area chart, no axes, gradient fill) ────────────────────
// Minimal hand-drawn CustomPaint sparkline — avoids fl_chart dependency for
// this lightweight visual. 4..12 datapoints; renders inside a fixed height.
class LaporanSparkline extends StatelessWidget {
  const LaporanSparkline({
    super.key,
    required this.points,
    required this.color,
  });

  final List<DailyIncomePoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: points.map((p) => p.totalNominal).toList(growable: false),
        color: color,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);
    final dx = size.width / (values.length - 1);

    // Build smooth path (tension ~0.4 via midpoints)
    final path = Path();
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final y = size.height - ((values[i] - minV) / range) * size.height;
      points.add(Offset(i * dx, y));
    }
    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p = points[i];
      final n = points[i + 1];
      final cx = (p.dx + n.dx) / 2;
      path.quadraticBezierTo(p.dx, p.dy, cx, (p.dy + n.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Area fill (gradient teal 0.2 → 0)
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(area, areaPaint);

    // Line stroke
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

// ── Top 5 obat data shape (F0.5 #8 — owner eksekutif) ───────────────────────
class LaporanTopObatData {
  const LaporanTopObatData({
    required this.nama,
    required this.qty,
    required this.nominal,
    required this.kategori,
  });
  final String nama;
  final int qty;
  final int nominal;
  final String kategori;
}

// ── Top 5 obat row (Stitch: 32px primary-container chip + 2-line text) ─────
class LaporanTopObatRow extends StatelessWidget {
  const LaporanTopObatRow({super.key, required this.rank, required this.item});
  final int rank;
  final LaporanTopObatData item;

  @override
  Widget build(BuildContext context) {
    final teal = cprimaryStitch(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              '$rank',
              style: AppTextStyles.labelLg.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSm.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  item.kategori,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'x${item.qty}',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rp ${item.nominal}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// NOTE: A second (broken) `LaporanSparkline` definition used to live here.
// It took `List<double>` instead of `List<DailyIncomePoint>` and produced
// duplicate-definition errors. Removed in Phase B; the canonical sparkline
// (taking `List<DailyIncomePoint>`) is defined at the top of this file.
