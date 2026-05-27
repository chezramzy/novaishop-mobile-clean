import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// A soft, rounded surface container. The default building block for
/// grouping content. Optionally tappable.
///
/// When [color] is omitted the card uses the theme surface colour, so it
/// stays correct in both light and dark mode.
class NovaCard extends StatelessWidget {
  const NovaCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.color,
    this.radius = AppSpacing.radiusLg,
    this.border,
    this.elevated = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  /// Surface colour. When null, resolves to the theme surface.
  final Color? color;
  final double radius;
  final BoxBorder? border;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(radius);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: borderRadius,
        border: border,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: colors.shadow
                      .withValues(alpha: colors.isDark ? .35 : .06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );

    return Padding(
      padding: margin,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
