import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppCardButton extends StatelessWidget {
  const AppCardButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? LightColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 32, color: Colors.white),
                  const SizedBox(height: 10),
                ],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
