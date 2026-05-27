import 'package:flutter/widgets.dart';

import 'animations.dart';
import 'app_motion.dart';

/// Helpers that apply a cascading entrance to list and grid children.
class StaggeredEntrance {
  const StaggeredEntrance._();

  /// Wraps [child] at [index] with a staggered fade-slide entrance.
  /// Use inside `itemBuilder` of a [ListView] or [GridView].
  static Widget item(
    int index,
    Widget child, {
    Duration perItemDelay = AppMotion.stagger,
    Duration baseDelay = Duration.zero,
    int maxStaggered = 12,
  }) {
    final clamped = index.clamp(0, maxStaggered);
    return child.fadeSlideIn(
      delay: baseDelay + perItemDelay * clamped,
    );
  }

  /// Applies a staggered entrance to a fixed list of [children].
  static List<Widget> all(
    List<Widget> children, {
    Duration perItemDelay = AppMotion.stagger,
    Duration baseDelay = Duration.zero,
    int maxStaggered = 12,
  }) {
    return [
      for (var i = 0; i < children.length; i++)
        item(
          i,
          children[i],
          perItemDelay: perItemDelay,
          baseDelay: baseDelay,
          maxStaggered: maxStaggered,
        ),
    ];
  }
}

/// A [Column] whose children animate in one after another.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
    this.perItemDelay = AppMotion.stagger,
    super.key,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration perItemDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: StaggeredEntrance.all(children, perItemDelay: perItemDelay),
    );
  }
}
