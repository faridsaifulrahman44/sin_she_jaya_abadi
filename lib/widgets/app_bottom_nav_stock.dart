import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/design_system/app_tokens.dart';
import '../core/theme/app_theme.dart';

/// Bottom navigation shell — 5 tab: Home, Patients, POS, Stock, More.
/// F0.5 redesign for Halaman 6 (stok_alert) and Halaman 7
/// (sinkronisasi_inventaris). The "Stock" tab is the active one.
class AppBottomNavStock extends StatelessWidget {
  const AppBottomNavStock({super.key, this.currentIndex = 3});

  final int currentIndex;

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/pasien');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/transaksi-hub');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/stok-alert');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/akun');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _go(context, index),
      backgroundColor: ccardBg(context),
      indicatorColor: cteal(context).withValues(alpha: 0.16),
      destinations: const [
        NavigationDestination(
          icon: Icon(Symbols.home_rounded),
          selectedIcon: Icon(Symbols.home_rounded, fill: 1),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Symbols.group_rounded),
          selectedIcon: Icon(Symbols.group_rounded, fill: 1),
          label: 'Patients',
        ),
        NavigationDestination(
          icon: Icon(Symbols.point_of_sale_rounded),
          selectedIcon: Icon(Symbols.point_of_sale_rounded, fill: 1),
          label: 'POS',
        ),
        NavigationDestination(
          icon: Icon(Symbols.inventory_2_rounded),
          selectedIcon: Icon(Symbols.inventory_2_rounded, fill: 1),
          label: 'Stock',
        ),
        NavigationDestination(
          icon: Icon(Symbols.more_horiz_rounded),
          selectedIcon: Icon(Symbols.more_horiz_rounded, fill: 1),
          label: 'More',
        ),
      ],
    );
  }
}

/// Minimalist 5-tab horizontal nav for the white header band.
/// F0.5 Halaman 6/7 — sits between the logo/avatar and the page body.
class AppHeaderNavStock extends StatelessWidget {
  const AppHeaderNavStock({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Home', 'Patients', 'POS', 'Stock', 'More'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_labels.length, (i) {
        final active = i == currentIndex;
        return Padding(
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          child: InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                _labels[i],
                style: AppTextStyles.menuTitle.copyWith(
                  color: active ? cteal(context) : ctextSecondary(context),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
