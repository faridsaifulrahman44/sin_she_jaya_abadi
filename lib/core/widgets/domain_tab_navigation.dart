import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DomainTabBar extends StatelessWidget implements PreferredSizeWidget {
  const DomainTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.labelColor = Colors.white,
    this.unselectedLabelColor,
    this.indicatorColor = Colors.white,
  });

  final TabController controller;
  final List<Widget> tabs;
  final Color labelColor;
  final Color? unselectedLabelColor;
  final Color indicatorColor;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      dividerColor: labelColor.withValues(alpha: 0.18),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: indicatorColor,
          width: 3,
        ),
      ),
      labelColor: labelColor,
      unselectedLabelColor:
          unselectedLabelColor ?? labelColor.withValues(alpha: 0.65),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: tabs,
    );
  }
}

class SwipeableTabBarView extends StatelessWidget {
  const SwipeableTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.physics = const PageScrollPhysics(),
  });

  final TabController controller;
  final List<Widget> children;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const _TabSwipeScrollBehavior(),
      child: TabBarView(
        controller: controller,
        physics: physics,
        children: children,
      ),
    );
  }
}

class _TabSwipeScrollBehavior extends MaterialScrollBehavior {
  const _TabSwipeScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}
