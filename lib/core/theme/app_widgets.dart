import 'package:flutter/material.dart';

import '../ui/app_symbols.dart';
import '../ui/obat_asset_registry.dart';
import '../utils/obat_foto_resolver.dart';
import 'app_colors.dart';

class ModernPageHeader extends StatelessWidget {
  const ModernPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class ModernSearchBar extends StatelessWidget {
  const ModernSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Cari...',
    this.onClear,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon: Icon(AppSymbols.cari, color: colorScheme.onSurfaceVariant, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(AppSymbols.close, color: colorScheme.onSurfaceVariant, size: 18),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Horizontal radio group for forms.
///
/// Usage:
/// ```dart
/// RadioGroup<StatusHadir>(
///   groupValue: _status,
///   onChanged: (v) => setState(() => _status = v),
///   child: Column([
///     RadioListTile<StatusHadir>(value: StatusHadir.hadir, title: Text('Hadir')),
///     RadioListTile<StatusHadir>(value: StatusHadir.tidakHadir, title: Text('Tidak Hadir')),
///   ]),
/// )
/// ```
class RadioGroup<T extends Object> extends StatelessWidget {
  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class GradientFAB extends StatelessWidget {
  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label = 'Tambah',
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? DarkColors.primary : LightColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class ModernListCard extends StatelessWidget {
  const ModernListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.icon,
    this.accentColor,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.leading,
    this.trailing,
    this.trailingPopup,
  });

  final String title;
  final String? subtitle;
  final String? trailingText;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? leading;
  final Widget? trailing;
  final PopupMenuButton<dynamic>? trailingPopup;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? DarkColors.borderSubtle : LightColors.divider,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                if (leading != null)
                  leading!
                else if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon!, color: color, size: 22),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  trailing!,
                ] else if (trailingText != null) ...[
                  Text(
                    trailingText!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (trailingPopup != null) ...[
                    const SizedBox(width: 4),
                    trailingPopup!,
                  ],
                ] else ...[
                  if (trailingPopup != null) trailingPopup!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = color ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: c),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
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

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).brightness == Brightness.dark
        ? DarkColors.shimmer
        : LightColors.shimmer;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final shimmer = Theme.of(context).brightness == Brightness.dark
        ? DarkColors.shimmer
        : LightColors.shimmer;
    final cardBg = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(height: 14, width: 140),
                SizedBox(height: 6),
                SkeletonLine(height: 11, width: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
    this.accentColor,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  /// Optional domain accent color. If provided, shows a 4dp leading strip.
  final Color? accentColor;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? DarkColors.primary : LightColors.primary;
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: primary,
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else if (automaticallyImplyLeading &&
                      Navigator.canPop(context))
                    IconButton(
                      icon: Icon(AppSymbols.arrowBack, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: centerTitle
                        ? Center(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            // Bottom border
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  height: 1, color: dividerColor.withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget foto obat dengan placeholder otomatis.
///
/// ## Prioritas sumber gambar (sejak transisi ke Supabase Storage)
/// 1) `fotoKey` + `fotoUpdatedAt` → Supabase Storage `obat-images`  [PRIORITAS 1]
/// 2) `fotoUrl` legacy → backward compat only                            [PRIORITAS 2]
/// 3) [ObatAssetRegistry] fallback → hanya jika 1 & 2 gagal            [PRIORITAS 3]
/// 4) Placeholder huruf awal nama obat                                   [PRIORITAS 4]
///
/// Contoh:
/// ```dart
/// ObatImage(
///   namaObat: 'Bodrex Extra',
///   fotoKey: obat.fotoKey,
///   fotoUpdatedAt: obat.fotoUpdatedAt,
///   fotoUrl: obat.fotoUrl,        // legacy, opsional
///   width: 50,
///   height: 50,
/// )
/// ```
class ObatImage extends StatelessWidget {
  const ObatImage({
    super.key,
    required this.namaObat,
    this.fotoKey,
    this.fotoUpdatedAt,
    this.fotoUrl,
    this.width,
    this.height,
    this.borderRadius = 10,
  });

  final String namaObat;

  /// Storage key di bucket `obat-images`. Prioritas 1.
  final String? fotoKey;

  /// Timestamp update foto terakhir — untuk cache busting. Prioritas 1.
  final DateTime? fotoUpdatedAt;

  /// Legacy field. Prioritas 2 — backward compat only.
  final String? fotoUrl;

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = width ?? 50.0;

    // ── Prioritas 1: fotoKey → Supabase Storage ────────────────────────────
    final storageUri = ObatFotoResolver.resolveStorageUrl(
      fotoKey: fotoKey,
      fotoUpdatedAt: fotoUpdatedAt,
      fotoUrl: null, // legacy fotoUrl diproses di prioritas 2
    );

    if (storageUri != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          storageUri.toString(),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLegacyOrAssetOrPlaceholder(
            isDark: isDark,
            size: size,
          ),
        ),
      );
    }

    return _buildLegacyOrAssetOrPlaceholder(isDark: isDark, size: size);
  }

  Widget _buildLegacyOrAssetOrPlaceholder({
    required bool isDark,
    required double size,
  }) {
    // ── Prioritas 2: legacy fotoUrl ─────────────────────────────────────────
    final legacyUri = _resolveLegacyUrl(fotoUrl);
    if (legacyUri != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          legacyUri,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildAssetOrPlaceholder(isDark: isDark, size: size),
        ),
      );
    }

    return _buildAssetOrPlaceholder(isDark: isDark, size: size);
  }

  Widget _buildAssetOrPlaceholder({
    required bool isDark,
    required double size,
  }) {
    // ── Prioritas 3: registry asset lokal fallback ─────────────────────────
    final assetPath = ObatAssetRegistry.resolve(namaObat);
    if (assetPath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _PlaceholderImage(
            namaObat: namaObat,
            size: size,
            isDark: isDark,
            borderRadius: borderRadius,
          ),
        ),
      );
    }

    // ── Prioritas 4: placeholder huruf awal ────────────────────────────────
    return _PlaceholderImage(
      namaObat: namaObat,
      size: size,
      isDark: isDark,
      borderRadius: borderRadius,
    );
  }

  /// Parse legacy fotoUrl.
  ///
  /// Mendukung:
  /// - URL lengkap (http:// / https://)
  /// - Storage path relatif (misal: `nama_obat.png`)
  String? _resolveLegacyUrl(String? rawFotoUrl) {
    final value = rawFotoUrl?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // Asumsikan storage path relatif → resolve ke public URL
    final storagePath = value.startsWith('/') ? value.substring(1) : value;
    if (storagePath.isEmpty) return null;

    try {
      return Uri.parse(
        ObatFotoResolver.resolveStorageUrl(
              fotoKey: storagePath,
              fotoUpdatedAt: null,
              fotoUrl: null,
            )?.toString() ??
            '',
      ).toString();
    } catch (_) {
      return null;
    }
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({
    required this.namaObat,
    required this.size,
    required this.isDark,
    this.borderRadius = 10,
  });

  final String namaObat;
  final double size;
  final bool isDark;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? DarkColors.obatBlueSoft : LightColors.obatBlueSoft;
    final fg = isDark ? DarkColors.obatBlue : LightColors.obatBlue;
    final initial = namaObat.isNotEmpty ? namaObat[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: (size * 0.4).clamp(12.0, 24.0),
          ),
        ),
      ),
    );
  }
}

Future<bool> showModernConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Hapus',
  String cancelText = 'Batal',
  bool isDanger = true,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final dangerColor = colorScheme.error;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: isDanger ? dangerColor : colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showModernSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final bgColor = isError ? colorScheme.error : colorScheme.primary;
  final contentColor = isError ? colorScheme.onError : colorScheme.onPrimary;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon ?? (isError ? AppSymbols.error : AppSymbols.success), color: contentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: contentColor))),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
