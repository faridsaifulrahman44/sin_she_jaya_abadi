import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_theme.dart';

class LaporanLoadingBox extends StatelessWidget {
  const LaporanLoadingBox({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cindigo(context) : ccardBg(context),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? conPrimary(context) : ctextSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

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
  final List<List<dynamic>> icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final acc = accentColor ?? cindigo(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: acc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: HugeIcon(icon: icon, color: acc),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ctextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: ctextSecondary(context)),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ccardBg(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ctextPrimary(context),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: ctextSecondary(context)),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ctextPrimary(context),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class LaporanInsightCard extends StatelessWidget {
  const LaporanInsightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isSuccess = false,
    this.isIndigo = false,
  });

  final String title;
  final String subtitle;
  final List<List<dynamic>> icon;
  final bool isSuccess;
  final bool isIndigo;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSuccess
        ? (cisDark(context) ? DarkColors.success : const Color(0xFF10B981))
        : isIndigo
            ? (cisDark(context) ? DarkColors.indigo : const Color(0xFF6366F1))
            : (cisDark(context) ? DarkColors.navy : const Color(0xFF1E3A8A));
    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: HugeIcon(icon: icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
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
