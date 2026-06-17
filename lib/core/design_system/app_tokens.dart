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
  // F0.5: extended scale (1.25 progression) untuk hero/auth surface
  static const sm2 = 18.0;
  static const sm3 = 32.0;
  static const sm4 = 40.0;
  static const sm5 = 48.0;
  static const sm6 = 56.0;
  // F0.6g: extended fine-grained values (off-grid interpolations untuk
  // hero branding, certificate border, dan padlock spacing)
  static const sm11 = 11.0;
  static const sm115 = 11.5;
  static const sm135 = 13.5;
  static const sm14 = 14.0;
  static const sm155 = 15.5;
  static const sm18 = 18.0;
  static const sm20 = 20.0;
  static const sm22 = 22.0;
  static const sm28 = 28.0;
  static const sm44 = 44.0;
  static const sm52 = 52.0;
  static const sm88 = 88.0;
  static const sm160 = 160.0;
}

class AppIconSize {
  const AppIconSize._();

  // F0.6g: ukuran ikon spesifik yang tidak masuk AppRadius/AppSpacing scale
  static const size14 = 14.0;
  static const size15 = 15.0;
  static const size16 = 16.0;
  static const size20 = 20.0;
  static const size28 = 28.0;
  static const size160 = 160.0; // hero branding circle
}

class AppRadius {
  const AppRadius._();

  static const xs = 6.0;
  static const sm = 8.0;
  static const sm10 = 10.0;
  static const md = 12.0;
  static const lg14 = 14.0;
  static const lg = 16.0;
  // F0.6h: report card pixel sizes for SVG/Icon container dimensions
  static const size4 = 4.0;
  static const size6 = 6.0;
  static const size8 = 8.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const full = 999.0;
  static const size24 = 24.0; // F0.6g — Stitch login branding badge
  static const size11 = 11.0;
  static const size11half = 11.5;
  static const size12 = 12.0;
  static const size12half = 12.5;
  static const size13half = 13.5;
  static const size14 = 14.0;
  static const size15half = 15.5;
  static const size16 = 16.0;
  static const size18 = 18.0;
  static const size20 = 20.0;
  static const size22 = 22.0;
  static const size28 = 28.0;
  static const size44 = 44.0;
  static const size52 = 52.0;
  static const size88 = 88.0;
  static const size160 = 160.0;
}

class AppTextStyles {
  const AppTextStyles._();

  static const metric = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );

  // F0.5: off-grid interpolations (12.5px, 17/w700) untuk hal2 yang
  // tidak match ke scale generik. Digunakan di dashboard + transaksi.
  static const metricBody = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );

  static const metricBold = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
  );

  static const menuTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
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

  // F0.5 #5: semantic named tokens for dashboard — interpolations
  // 12px/w500 label-sm, 14px/w600 label-lg, 20px/w700 headline-md.
  static const labelSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const labelLg = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const headlineMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
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

  // F0.5: extended scale untuk hero/auth surface
  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );
}

class AppColors {
  const AppColors._();

  // ── Brand palette (per step1-token-map.md) ──────────
  // Teal — primary
  static const primary = Color(0xFF00897B);
  static const primaryDark = Color(0xFF00695C);
  static const primaryLight = Color(0xFF4DB6AC);

  // Blue — header
  static const headerBlue = Color(0xFF1565C0);
  static const headerBlueDark = Color(0xFF0D47A1);

  // Navy/brand gradient (F0.6g — Stitch login_premium desktop branding band)
  static const brandNavy = Color(0xFF1E3A8A);
  static const brandBlueMid = Color(0xFF1E40AF);
  static const brandBlueLight = Color(0xFF1D4ED8);

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
  static const borderMuted = Color(0xFFE2E8F0); // softer border for auth surface

  // ── Legacy slate (F0.6d, for gradient banding) ───────────────────────────
  static const legacySlate50 = Color(0xFFF5F7FA); // lightest band (top)
  static const legacySlate100 = Color(0xFFEEF2F6); // mid band

  // Dark surface (auth/hero gradient base)
  static const surfaceDark = Color(0xFF0D1117);
  static const surfaceDeep = Color(0xFF1A2332);

  // ── Material 3 surface tokens (KEEP #16 design system) ────────────────────
  static const surfaceDim = Color(0xFFD7DBDA);
  static const surfaceBright = Color(0xFFF6FAF9);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF0F4F3);
  static const surfaceContainer = Color(0xFFEBEFEE);
  static const surfaceContainerHigh = Color(0xFFE5E9E8);
  static const surfaceContainerHighest = Color(0xFFDFE3E2);
  static const onSurface = Color(0xFF181C1C);
  static const onSurfaceVariant = Color(0xFF3E4949);
  static const inverseSurface = Color(0xFF2C3131);
  static const inverseOnSurface = Color(0xFFEDF2F1);
  static const outline = Color(0xFF6E7979);
  static const outlineVariant = Color(0xFFBDC9C8);
  static const surfaceTint = Color(0xFF006A6A);

  // ── Material 3 primary / secondary / tertiary (KEEP #16) ──────────────────
  static const primaryContainer = Color(0xFF008080);
  static const onPrimaryContainer = Color(0xFFE3FFFE);
  static const inversePrimary = Color(0xFF76D6D5);
  // Standard on-primary (white) — used for text/icons over `primary` fill.
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF29695B);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFACEDDA);
  static const onSecondaryContainer = Color(0xFF2E6D5F);
  static const tertiary = Color(0xFF8B4823);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFA96039);
  static const onTertiaryContainer = Color(0xFFFFF9F7);

  // ── Material 3 error tokens (KEEP #16) ────────────────────────────────────
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // ── Material 3 fixed tones (KEEP #16) ──────────────────────────────────────
  static const primaryFixed = Color(0xFF93F2F2);
  static const primaryFixedDim = Color(0xFF76D6D5);
  static const onPrimaryFixed = Color(0xFF002020);
  static const onPrimaryFixedVariant = Color(0xFF004F4F);
  static const secondaryFixed = Color(0xFFAFEFDD);
  static const secondaryFixedDim = Color(0xFF94D3C1);
  static const onSecondaryFixed = Color(0xFF00201A);
  static const onSecondaryFixedVariant = Color(0xFF065043);
  static const tertiaryFixed = Color(0xFFFFDBCB);
  static const tertiaryFixedDim = Color(0xFFFFB692);
  static const onTertiaryFixed = Color(0xFF341100);
  static const onTertiaryFixedVariant = Color(0xFF733512);

  // ── Semantic accents (KEEP #16) ────────────────────────────────────────────
  static const info = Color(0xFF1565C0);

  // ── Legacy / semantic (pre-existing) ──────────────────────────────────────
  static const positive = Color(0xFF10B981);
  static const accent = Color(0xFF14B8A6);

  // ── F0.5 #8: Stitch KEEP #8 teal clinical palette ────────────────────────
  // Named explicitly for F0.5#8 migration — co-exists with `primary` (legacy
  // #00897B) and the M3 `primaryContainer` (#008080). These `tealStitch*` are
  // reserved for the laporan_eksekutif_owner screen to match the Stitch
  // visual contract.
  static const tealStitchPrimary = Color(0xFF006565);     // #006565
  static const tealStitchContainer = Color(0xFF008080);   // #008080
  static const tealStitchSecondary = Color(0xFFACEDDA);   // #acedda
  static const scaffoldBgStitch = Color(0xFFF6FAF9);      // #f6faf9
  static const surfaceContainerStitch = Color(0xFFEBEFEE); // #ebefee
  static const onSurfaceStitch = Color(0xFF181C1C);       // #181c1c
  static const outlineVariantStitch = Color(0xFFBDC9C8);  // #bdc9c8
}
