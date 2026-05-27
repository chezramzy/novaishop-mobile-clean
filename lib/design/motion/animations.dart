import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_motion.dart';

/// Reusable [flutter_animate] entrance helpers. Use the [WidgetMotionX]
/// extension on any widget to apply a consistent, subtle animation.
extension WidgetMotionX on Widget {
  /// Fades the widget in while sliding it up slightly. Ideal for sections
  /// and page content.
  Widget fadeSlideIn({
    Duration? duration,
    Duration delay = Duration.zero,
    double beginOffsetY = 0.08,
    Curve curve = AppMotion.enter,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppMotion.normal, curve: curve)
        .slideY(
          begin: beginOffsetY,
          end: 0,
          duration: duration ?? AppMotion.normal,
          curve: curve,
        );
  }

  /// Pops the widget in with a slight scale overshoot. Ideal for badges,
  /// chips and call-to-action buttons.
  Widget popIn({
    Duration? duration,
    Duration delay = Duration.zero,
    double beginScale = 0.85,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration ?? AppMotion.fast)
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1, 1),
          duration: duration ?? AppMotion.normal,
          curve: AppMotion.emphasized,
        );
  }

  /// Applies a looping shimmer sweep. Used by skeleton loaders.
  Widget shimmerLoop({
    Duration? duration,
    Color? color,
  }) {
    return animate(onPlay: (controller) => controller.repeat()).shimmer(
      duration: duration ?? const Duration(milliseconds: 1100),
      color: color,
    );
  }
}

/// Free-function form of the shimmer effect for callers that prefer it.
Widget shimmer(Widget child, {Duration? duration, Color? color}) {
  return child.shimmerLoop(duration: duration, color: color);
}

/// Free-function form of [WidgetMotionX.fadeSlideIn].
Widget fadeSlideIn(
  Widget child, {
  Duration? duration,
  Duration delay = Duration.zero,
}) {
  return child.fadeSlideIn(duration: duration, delay: delay);
}

/// Free-function form of [WidgetMotionX.popIn].
Widget popIn(
  Widget child, {
  Duration? duration,
  Duration delay = Duration.zero,
}) {
  return child.popIn(duration: duration, delay: delay);
}
