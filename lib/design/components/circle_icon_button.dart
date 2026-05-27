import 'package:flutter/material.dart';

import '../tokens/nova_colors.dart';

/// A circular, filled icon button used for back arrows and compact actions.
///
/// When [backgroundColor] / [foregroundColor] are omitted they resolve from
/// the active theme, so the button stays correct in light and dark mode.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 44,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: size,
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor ?? colors.surface,
          foregroundColor: foregroundColor ?? colors.textPrimary,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
