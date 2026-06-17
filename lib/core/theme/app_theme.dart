import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_tokens.dart';
import 'app_colors.dart';
export 'app_colors.dart' show LightColors, DarkColors;
export 'app_widgets.dart';

// F0.5: Global font family override — Stitch KEEP pakai Plus Jakarta Sans.
// Di-apply di ThemeData level agar semua DefaultTextStyle mewarisi.
// TextStyle eksplisit di TextTheme yang tidak set fontFamily juga ikut inherit.
const String _kFontFamily = 'Plus Jakarta Sans';

// ============================================================================
// LIGHT THEME DATA
// ============================================================================
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _kFontFamily,

    // ── Colors ──────────────────────────────────────────────
    colorScheme: const ColorScheme.light(
      primary: LightColors.primary,
      onPrimary: LightColors.textOnPrimary,
      primaryContainer: LightColors.primaryLight,
      onPrimaryContainer: LightColors.primaryDark,
      secondary: LightColors.secondary,
      onSecondary: LightColors.textOnPrimary,
      secondaryContainer: LightColors.secondaryLight,
      onSecondaryContainer: LightColors.secondaryDark,
      tertiary: LightColors.tertiary,
      onTertiary: LightColors.textOnPrimary,
      tertiaryContainer: LightColors.tertiaryLight,
      onTertiaryContainer: LightColors.tertiaryDark,
      error: LightColors.danger,
      onError: LightColors.textOnPrimary,
      errorContainer: LightColors.dangerLight,
      onErrorContainer: LightColors.danger,
      surface: LightColors.card,
      onSurface: LightColors.textPrimary,
      surfaceContainerHighest: LightColors.surface,
      onSurfaceVariant: LightColors.textSecondary,
      outline: LightColors.divider,
      outlineVariant: LightColors.divider,
      shadow: LightColors.shadowLight,
      scrim: Colors.black26,
    ),

    scaffoldBackgroundColor: LightColors.scaffold,

    // ── AppBar ──────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: LightColors.primary,
      foregroundColor: LightColors.textOnPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: LightColors.textOnPrimary,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: LightColors.textOnPrimary),
    ),

    // ── Cards ──────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: LightColors.card,
      elevation: 0,
      shadowColor: LightColors.shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // ── Elevated Button ─────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LightColors.primary,
        foregroundColor: LightColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Filled Button ──────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LightColors.primary,
        foregroundColor: LightColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Outlined Button ────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LightColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: LightColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Text Button ────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LightColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // ── Floating Action Button ──────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LightColors.primary,
      foregroundColor: LightColors.textOnPrimary,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── Input Decoration ───────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LightColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.inputBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: LightColors.inputFocusRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LightColors.danger, width: 2),
      ),
      hintStyle: const TextStyle(
        color: LightColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: LightColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: LightColors.danger,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── Chip ───────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: LightColors.surface,
      selectedColor: LightColors.primaryLight,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LightColors.textPrimary,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: LightColors.textOnPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ── List Tile ──────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: LightColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: LightColors.textSecondary,
      ),
      iconColor: LightColors.textSecondary,
    ),

    // ── Divider ────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: LightColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ── Dialog ─────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: LightColors.card,
      elevation: 8,
      shadowColor: LightColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: LightColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: LightColors.textSecondary,
      ),
    ),

    // ── Bottom Sheet ────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LightColors.card,
      elevation: 8,
      shadowColor: LightColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: LightColors.divider,
    ),

    // ── Popup Menu ──────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: LightColors.card,
      elevation: 8,
      shadowColor: LightColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: LightColors.textPrimary,
      ),
    ),

    // ── Snackbar ───────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LightColors.textPrimary,
      contentTextStyle: const TextStyle(
        color: LightColors.textOnPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Progress Indicator ─────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LightColors.primary,
      circularTrackColor: LightColors.divider,
      linearTrackColor: LightColors.divider,
    ),

    // ── Tab Bar ─────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      labelColor: LightColors.primary,
      unselectedLabelColor: LightColors.textMuted,
      indicatorColor: LightColors.primary,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),

    // ── Icon ───────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: LightColors.textSecondary,
      size: 24,
    ),

    // ── Text Theme ─────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: LightColors.textPrimary),
      displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: LightColors.textPrimary),
      displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: LightColors.textPrimary),
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: LightColors.textPrimary),
      headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: LightColors.textPrimary),
      headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: LightColors.textPrimary),
      titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: LightColors.textPrimary),
      titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary),
      titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary),
      bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: LightColors.textPrimary),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: LightColors.textPrimary),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: LightColors.textSecondary),
      labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary),
      labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LightColors.textPrimary),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: LightColors.textMuted),
    ),
  );
}

// ============================================================================
// DARK THEME DATA
// ============================================================================
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _kFontFamily,

    // ── Colors ──────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: DarkColors.primary,
      onPrimary: DarkColors.textOnPrimary,
      primaryContainer: DarkColors.primaryDark,
      onPrimaryContainer: DarkColors.primaryLight,
      secondary: DarkColors.secondary,
      onSecondary: DarkColors.textOnPrimary,
      secondaryContainer: DarkColors.secondaryDark,
      onSecondaryContainer: DarkColors.secondaryLight,
      tertiary: DarkColors.tertiary,
      onTertiary: DarkColors.textPrimary,
      tertiaryContainer: DarkColors.tertiaryDark,
      onTertiaryContainer: DarkColors.tertiaryLight,
      error: DarkColors.danger,
      onError: DarkColors.textOnPrimary,
      errorContainer: DarkColors.dangerDim,
      onErrorContainer: DarkColors.dangerLight,
      surface: DarkColors.card,
      onSurface: DarkColors.textPrimary,
      surfaceContainerHighest: DarkColors.surfaceHigh,
      onSurfaceVariant: DarkColors.textSecondary,
      outline: DarkColors.divider,
      outlineVariant: DarkColors.borderActive,
      shadow: DarkColors.shadowLight,
      scrim: Colors.black54,
    ),

    scaffoldBackgroundColor: DarkColors.scaffold,

    // ── AppBar ──────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: DarkColors.card,
      foregroundColor: DarkColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        color: DarkColors.textPrimary,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: DarkColors.textPrimary),
    ),

    // ── Cards ──────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: DarkColors.card,
      elevation: 0,
      shadowColor: DarkColors.shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),

    // ── Elevated Button ─────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DarkColors.primary,
        foregroundColor: DarkColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Filled Button ──────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DarkColors.primary,
        foregroundColor: DarkColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Outlined Button ────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DarkColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        side: const BorderSide(color: DarkColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),

    // ── Text Button ────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DarkColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // ── Floating Action Button ──────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: DarkColors.primary,
      foregroundColor: DarkColors.textOnPrimary,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── Input Decoration ───────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarkColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: DarkColors.danger, width: 2),
      ),
      hintStyle: const TextStyle(
        color: DarkColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: DarkColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: DarkColors.dangerLight,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // ── Chip ───────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: DarkColors.surface,
      selectedColor: DarkColors.primaryDark,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DarkColors.textPrimary,
      ),
      secondaryLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DarkColors.textOnPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ── List Tile ──────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DarkColors.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: DarkColors.textSecondary,
      ),
      iconColor: DarkColors.textSecondary,
    ),

    // ── Divider ────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: DarkColors.divider,
      thickness: 1,
      space: 1,
    ),

    // ── Dialog ─────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: DarkColors.card,
      elevation: 8,
      shadowColor: DarkColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: DarkColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DarkColors.textSecondary,
      ),
    ),

    // ── Bottom Sheet ────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: DarkColors.card,
      elevation: 8,
      shadowColor: DarkColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: DarkColors.divider,
    ),

    // ── Popup Menu ──────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: DarkColors.surfaceHigh,
      elevation: 8,
      shadowColor: DarkColors.shadowMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: DarkColors.textPrimary,
      ),
    ),

    // ── Snackbar ───────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: DarkColors.surfaceHigh,
      contentTextStyle: const TextStyle(
        color: DarkColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Progress Indicator ─────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DarkColors.primary,
      circularTrackColor: DarkColors.divider,
      linearTrackColor: DarkColors.divider,
    ),

    // ── Tab Bar ─────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      labelColor: DarkColors.primary,
      unselectedLabelColor: DarkColors.textMuted,
      indicatorColor: DarkColors.primary,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle:
          TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),

    // ── Icon ───────────────────────────────────────────────
    iconTheme: const IconThemeData(
      color: DarkColors.textSecondary,
      size: 24,
    ),

    // ── Text Theme ─────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary),
      displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary),
      displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary),
      headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: DarkColors.textPrimary),
      headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: DarkColors.textPrimary),
      headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: DarkColors.textPrimary),
      titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: DarkColors.textPrimary),
      titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary),
      titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary),
      bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary),
      bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: DarkColors.textPrimary),
      bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: DarkColors.textSecondary),
      labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary),
      labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DarkColors.textPrimary),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: DarkColors.textMuted),
    ),
  );
}

// ============================================================================
// THEME COLOR HELPERS — use these in page build methods for dark-mode support
// ============================================================================

/// App scaffold background (the outermost page background).
Color cscaffoldBg(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.scaffold : LightColors.scaffold;
}

/// Card / inner container background.
Color ccardBg(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.card : LightColors.card;
}

/// Subtle surface layer (between scaffold and card).
Color csurface(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.surface : LightColors.surface;
}

/// High-elevation surface (dialogs, bottom sheets in dark mode).
Color csurfaceHigh(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.surfaceHigh : LightColors.surface;
}

/// Primary brand color.
Color cprimary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.primary : LightColors.primary;
}

/// Primary variant / dark primary.
Color cprimaryDark(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.primaryDark : LightColors.primaryDark;
}

/// Secondary / accent color.
Color csecondary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.secondary : LightColors.secondary;
}

/// Primary text color.
Color ctextPrimary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.textPrimary : LightColors.textPrimary;
}

/// Secondary / muted text.
Color ctextSecondary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.textSecondary : LightColors.textSecondary;
}

/// Placeholder / hint text.
Color ctextMuted(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.textMuted : LightColors.textMuted;
}

/// Divider / border color.
Color cdivider(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.divider : LightColors.divider;
}

/// Success green.
Color csuccess(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.success : LightColors.success;
}

/// Danger / error red.
Color cdanger(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.danger : LightColors.danger;
}

/// Warning amber.
Color cwarning(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.warning : LightColors.warning;
}

/// Navy — used for login/desktop branding.
Color cnavy(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.navy : LightColors.navy;
}

/// Border color for cards in current theme.
Color cborder(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.borderSubtle : LightColors.divider;
}

/// Shimmer / skeleton color for loading states.
Color cshimmer(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.shimmer : LightColors.shimmer;
}

/// Teal accent color.
Color cteal(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.teal : LightColors.teal;
}

/// Purple accent color.
Color cpurple(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.purple : LightColors.purple;
}

// ── Domain color helpers ──────────────────────────────────────────────────────

/// Indigo — Laporan domain accent.
Color cindigo(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.indigo : LightColors.indigo;
}

/// Indigo soft background for Laporan.
Color cindigoSoft(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.indigoSoft : LightColors.indigoSoft;
}

/// Blue accent — Data Obat.
Color cobatBlue(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatBlue : LightColors.obatBlue;
}

/// Blue soft background — Data Obat.
Color cobatBlueSoft(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatBlueSoft : LightColors.obatBlueSoft;
}

/// Green accent — Obat Masuk.
Color cobatGreen(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatGreen : LightColors.obatGreen;
}

/// Green soft background — Obat Masuk.
Color cobatGreenSoft(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatGreenSoft : LightColors.obatGreenSoft;
}

/// Amber accent — Obat Keluar.
Color cobatAmber(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatAmber : LightColors.obatAmber;
}

/// Amber soft background — Obat Keluar.
Color cobatAmberSoft(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? DarkColors.obatAmberSoft : LightColors.obatAmberSoft;
}

/// Foreground text on primary-colored surfaces (always white).
Color conPrimary(BuildContext context) => Colors.white;

/// Foreground text on danger-colored surfaces (always white).
Color conDanger(BuildContext context) => Colors.white;

/// Whether the current theme is dark mode.
bool cisDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// ── F0.5 #8: Stitch KEEP #8 (laporan_eksekutif_owner) helpers ───────────────

/// Stitch teal primary (#006565) — used for the solid teal insight callout
/// and the active period chip on the executive report page.
Color cprimaryStitch(BuildContext context) {
  return cisDark(context) ? const Color(0xFF93F2F2) : AppColors.tealStitchPrimary;
}

/// Stitch surface-container (#EBEFEE in light, M3 dark surface in dark).
/// Distinct from `csurface` (between scaffold and card) and `ccardBg` (white).
Color csurfaceContainer(BuildContext context) {
  return cisDark(context) ? DarkColors.surfaceHigh : AppColors.surfaceContainerStitch;
}

/// Stitch scaffold background (#F6FAF9).
Color cscaffoldBgStitch(BuildContext context) {
  return cisDark(context) ? DarkColors.scaffold : AppColors.scaffoldBgStitch;
}

/// Stitch outline-variant (#BDC9C8) for thin 1px borders under the AppBar.
Color coutlineVariantStitch(BuildContext context) {
  return cisDark(context) ? DarkColors.borderActive : AppColors.outlineVariantStitch;
}

/// M3 primaryContainer — used as the active period chip background
/// and avatar circle fill in the Stitch KEEP #8 header.
Color cprimaryContainer(BuildContext context) {
  return cisDark(context) ? DarkColors.primaryDark : LightColors.primaryLight;
}

/// M3 onPrimaryContainer — used as text/icon color over [cprimaryContainer]
/// (e.g. the avatar circle and active period chip label).
Color conPrimaryContainer(BuildContext context) {
  return cisDark(context) ? LightColors.primaryLight : LightColors.primaryDark;
}
