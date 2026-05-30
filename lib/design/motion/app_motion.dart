import 'package:flutter/animation.dart';

/// Standard animation durations and curves. All NovaShop animations pull
/// their timing from here so motion stays consistent and subtle (≤ 400 ms).
class AppMotion {
  const AppMotion._();

  /// Quick micro-interactions (taps, toggles).
  static const Duration fast = Duration(milliseconds: 150);

  /// Default transitions (entrances, page changes).
  static const Duration normal = Duration(milliseconds: 250);

  /// Emphasised motion (hero-like reveals, staggered lists).
  static const Duration slow = Duration(milliseconds: 400);

  /// Standard easing for most transitions.
  static const Curve standard = Curves.easeOutCubic;

  /// Decelerating easing for entrances.
  static const Curve enter = Curves.easeOut;

  /// Accelerating easing for exits.
  static const Curve exit = Curves.easeIn;

  /// Springy easing for playful pop-in effects.
  static const Curve emphasized = Curves.easeOutBack;

  /// Per-item delay used by staggered list entrances.
  static const Duration stagger = Duration(milliseconds: 55);
}
