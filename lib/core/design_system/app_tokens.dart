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

  static const positive = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const accent = Color(0xFF14B8A6);
}
