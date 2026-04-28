import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../ui/app_icons.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.empty,
    this.color,
  });

  final String title;
  final String? message;
  final List<List<dynamic>> icon;

  /// Optional accent color. Falls back to theme primary if not provided.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = color ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(icon: icon, size: 32, color: accentColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
