import 'package:flutter/material.dart';

import '../motion/animations.dart';
import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// A single shimmering placeholder block, used to build loading skeletons.
class NovaSkeleton extends StatelessWidget {
  const NovaSkeleton({
    this.width = double.infinity,
    this.height = 16,
    this.radius = AppSpacing.radiusSm,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// A circular skeleton of the given [size].
  const NovaSkeleton.circle({double size = 48, super.key})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  final double width;
  final double height;
  final double radius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    ).shimmerLoop(color: colors.surfaceMuted);
  }
}

/// A vertical list of skeleton rows.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    this.itemCount = 6,
    this.itemHeight = 76,
    this.padding = AppSpacing.screenPadding,
    super.key,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Row(
        children: [
          NovaSkeleton.circle(size: 56),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NovaSkeleton(height: 14),
                SizedBox(height: AppSpacing.xs),
                NovaSkeleton(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A grid of skeleton cards, matching the catalogue product grid layout.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.72,
    this.padding = AppSpacing.screenPadding,
    super.key,
  });

  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: NovaSkeleton(
              height: double.infinity,
              radius: AppSpacing.radiusLg,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          NovaSkeleton(height: 12),
          SizedBox(height: AppSpacing.xxs),
          NovaSkeleton(width: 80, height: 12),
        ],
      ),
    );
  }
}
