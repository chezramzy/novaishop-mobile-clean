import 'package:flutter/material.dart';

import 'app_motion.dart';

/// Animated [PageRoute] factories. Use these for all imperative navigation
/// so page transitions stay consistent across the app.
class AppPageRoute {
  const AppPageRoute._();

  /// A simple cross-fade transition.
  static PageRoute<T> fade<T>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AppMotion.normal,
      reverseTransitionDuration: duration ?? AppMotion.normal,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: AppMotion.standard),
          child: child,
        );
      },
    );
  }

  /// A shared-axis style transition: the incoming page fades and slides in
  /// from the horizontal axis while the outgoing one slides slightly out.
  static PageRoute<T> sharedAxis<T>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AppMotion.normal,
      reverseTransitionDuration: duration ?? AppMotion.normal,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: AppMotion.standard);
        final curvedSecondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: AppMotion.standard,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.04, 0),
            ).animate(curvedSecondary),
            child: FadeTransition(opacity: curved, child: child),
          ),
        );
      },
    );
  }

  /// A vertical slide-up transition, suited to modal-like full screens.
  static PageRoute<T> slideUp<T>(
    Widget page, {
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AppMotion.normal,
      reverseTransitionDuration: duration ?? AppMotion.normal,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: AppMotion.standard);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }
}
