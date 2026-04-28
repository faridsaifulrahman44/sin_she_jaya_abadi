import 'package:flutter/material.dart';

// ============================================================================
// LIGHT THEME COLORS — Modern Premium Clinical
// Updated: clean, refined, neutral-first palette
// ============================================================================
class LightColors {
  LightColors._();

  // ── Fondasi global ─────────────────────────────────────────────────────────
  static const Color scaffold = Color(0xFFF6F8FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF1F5F9);

  // ── Primary brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // brand blue
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8); // active/hover

  // ── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFEA580C);

  // ── Tertiary ─────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF14B8A6);
  static const Color tertiaryLight = Color(0xFF2DD4BF);
  static const Color tertiaryDark = Color(0xFF0F766E);

  // ── Semantic status ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successSoft = Color(0xFFD1FAE5); // soft bg

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningSoft = Color(0xFFFEF3C7); // soft bg

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFCA5A5);
  static const Color dangerSoft = Color(0xFFFEE2E2); // soft bg

  // ── Domain accent — Obat ──────────────────────────────────────────────────
  // Data Obat: blue
  static const Color obatBlue = Color(0xFF2563EB);
  static const Color obatBlueSoft = Color(0xFFDBEAFE);
  // Obat Masuk: green
  static const Color obatGreen = Color(0xFF10B981);
  static const Color obatGreenSoft = Color(0xFFD1FAE5);
  // Obat Keluar: amber
  static const Color obatAmber = Color(0xFFF59E0B);
  static const Color obatAmberSoft = Color(0xFFFEF3C7);

  // ── Domain accent — Laporan ───────────────────────────────────────────────
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFF818CF8);
  static const Color indigoSoft = Color(0xFFEEF2FF); // soft bg

  // ── Domain accent — Pasien (TEAL — DO NOT CHANGE) ─────────────────────────
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFF2DD4BF);
  static const Color tealSoft = Color(0xFFCCFBF1); // soft bg

  // ── Chart series palette ──────────────────────────────────────────────────
  static const Color chart1 = Color(0xFF6366F1); // indigo
  static const Color chart2 = Color(0xFF14B8A6); // teal
  static const Color chart3 = Color(0xFFF59E0B); // amber
  static const Color chart4 = Color(0xFFF43F5E); // rose

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Input ─────────────────────────────────────────────────────────────────
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color inputFocusRing = Color(0xFF93C5FD);

  // ── Utility ───────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shimmer = Color(0xFFE2E8F0);
  static const Color overlay = Color(0x0A000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // ── Navy (auth/branding only) ─────────────────────────────────────────────
  static const Color navy = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF3B82F6);

  // ── Other accent variants ─────────────────────────────────────────────────
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFF22D3EE);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color pink = Color(0xFFEC4899);
}

// ============================================================================
// DARK THEME COLORS — Premium Modern Dashboard (minimal changes)
// ============================================================================
class DarkColors {
  DarkColors._();

  // Background
  static const Color scaffold = Color(0xFF0D1117);
  static const Color card = Color(0xFF161B26);
  static const Color surface = Color(0xFF1E2535);
  static const Color surfaceHigh = Color(0xFF252D3F);

  // Primary — electric indigo / sapphire
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color primaryDark = Color(0xFF4A44CC);

  // Secondary
  static const Color secondary = Color(0xFFFF6B8A);
  static const Color secondaryLight = Color(0xFFFF8FA8);
  static const Color secondaryDark = Color(0xFFCC4466);

  // Tertiary
  static const Color tertiary = Color(0xFF00D4FF);
  static const Color tertiaryLight = Color(0xFF66E5FF);
  static const Color tertiaryDark = Color(0xFF00A3C7);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF80E080);
  static const Color successDim = Color(0xFF1B3D1B);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningLight = Color(0xFFFFCC80);
  static const Color warningDim = Color(0xFF3D2A0A);
  static const Color danger = Color(0xFFEF5350);
  static const Color dangerLight = Color(0xFFFF8A80);
  static const Color dangerDim = Color(0xFF3D0F0F);

  // Domain accent — Obat
  static const Color obatBlue = Color(0xFF3B82F6);
  static const Color obatBlueSoft = Color(0xFF1E3A5F);
  static const Color obatGreen = Color(0xFF4CAF50);
  static const Color obatGreenSoft = Color(0xFF1B3D1B);
  static const Color obatAmber = Color(0xFFFFA726);
  static const Color obatAmberSoft = Color(0xFF3D2A0A);

  // Domain accent — Laporan
  static const Color indigo = Color(0xFF818CF8);
  static const Color indigoLight = Color(0xFFA5B4FC);
  static const Color indigoSoft = Color(0xFF1E2045);

  // Domain accent — Pasien (DO NOT CHANGE)
  static const Color teal = Color(0xFF26A69A);
  static const Color tealSoft = Color(0xFF003D3D);

  // Chart series palette (dark)
  static const Color chart1 = Color(0xFF818CF8);
  static const Color chart2 = Color(0xFF26A69A);
  static const Color chart3 = Color(0xFFFFA726);
  static const Color chart4 = Color(0xFFFB7185);

  // Accent variants
  static const Color purple = Color(0xFFBB86FC);
  static const Color purpleDim = Color(0xFF2D1F45);
  static const Color pink = Color(0xFFFF80AB);
  static const Color cyan = Color(0xFF18FFFF);
  static const Color cyanDim = Color(0xFF003D3D);

  // Navy
  static const Color navy = Color(0xFF1E3A5F);

  // Text
  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFF9AA0AB);
  static const Color textMuted = Color(0xFF5C6270);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Input
  static const Color inputBorder = Color(0xFF334155);
  static const Color inputFocusRing = Color(0xFF3B82F6);

  // Utility
  static const Color divider = Color(0xFF2A3045);
  static const Color shimmer = Color(0xFF2A3045);
  static const Color overlay = Color(0x33FFFFFF);
  static const Color shadowLight = Color(0x40000000);
  static const Color shadowMedium = Color(0x60000000);

  // Borders
  static const Color borderSubtle = Color(0xFF252D3F);
  static const Color borderActive = Color(0xFF3A4565);
}
