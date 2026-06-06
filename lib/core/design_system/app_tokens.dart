import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const xxs = 2.0;
  static const xs = 4.0;
  static const xs6 = 6.0;
  static const sm = 8.0;
  static const sm10 = 10.0;
  static const md = 12.0;
  static const md14 = 14.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const full = 999.0;
}

class AppTextStyles {
  const AppTextStyles._();

  static const metric = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const titleSm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const bodyMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const headline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const headlineLg = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const heroMetric = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const heroJumbo = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const labelXs = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}

class AppColors {
  const AppColors._();

  // ── Brand palette (per docs/superpowers/specs/step1-token-map.md) ──────────
  // Teal — primary
  static const primary = Color(0xFF00897B);
  static const primaryDark = Color(0xFF00695C);
  static const primaryLight = Color(0xFF4DB6AC);

  // Blue — header
  static const headerBlue = Color(0xFF1565C0);
  static const headerBlueDark = Color(0xFF0D47A1);

  // Accents
  static const accentCoral = Color(0xFFFF7043);
  static const accentAmber = Color(0xFFFFB300);
  static const accentGreen = Color(0xFF26A69A);

  // Surfaces
  static const surface = Color(0xFFF5F7FA);
  static const card = Color(0xFFFFFFFF);

  // Status
  static const danger = Color(0xFFEF5350);
  static const warning = Color(0xFFFF9800);
  static const success = Color(0xFF66BB6A);

  // Text
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  // Border
  static const border = Color(0xFFE5E7EB);

  // ── Legacy / semantic (pre-existing) ──────────────────────────────────────
  static const positive = Color(0xFF10B981);
  static const accent = Color(0xFF14B8A6);
}
