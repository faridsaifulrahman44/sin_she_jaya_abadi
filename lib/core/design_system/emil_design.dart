import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Emil Design System — motion & interaction tokens for SinShe Jaya Abadi.
/// Adopts principles from Emil's design system: reduced motion, tactile feedback,
/// and consistent animation curves across the app.
abstract final class EmilDesign {
  // ── Durations ──────────────────────────────────────────────────────────────
  static const fast    = Duration(milliseconds: 150);
  static const normal  = Duration(milliseconds: 300);
  static const slow    = Duration(milliseconds: 500);

  // ── Curves ─────────────────────────────────────────────────────────────────
  static const enter   = Curves.easeOutCubic;
  static const exit    = Curves.easeInCubic;
  static const gesture = Curves.easeOutCubic;
  static const toggle  = Curves.easeInOutCubic;
  static const bounce  = Curves.elasticOut;

  // ── Scale ──────────────────────────────────────────────────────────────────
  static const pressScale = 0.97;
  static const hoverScale = 1.04;

  // ── Adaptive duration ──────────────────────────────────────────────────────
  /// Returns zero duration if the system prefers reduced motion.
  static Duration adaptiveDuration(BuildContext context, Duration normalDuration) {
    return SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion
        ? Duration.zero
        : normalDuration;
  }

  // ── Adaptive curve ────────────────────────────────────────────────────────
  /// Returns linear if reduced motion is preferred.
  static Curve adaptiveCurve(Curve normal) {
    return SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion
        ? Curves.linear
        : normal;
  }

  // ── Page transitions ───────────────────────────────────────────────────────
  static const pageTransitionDuration = normal;

  static Route<T> pageRoute<T>({
    required Widget page,
    Key? key,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: pageTransitionDuration,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurveTween(curve: enter).animate(animation);
        return FadeTransition(opacity: curved, child: child);
      },
      reverseTransitionDuration: pageTransitionDuration,
    );
  }
}