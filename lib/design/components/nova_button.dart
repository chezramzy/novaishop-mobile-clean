import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// The visual variants supported by [NovaButton].
enum NovaButtonVariant {
  /// Lime background, dark text — the dominant call to action.
  primary,

  /// Dark background, lime text — secondary emphasis.
  secondary,

  /// Transparent background with text only — low emphasis.
  ghost,
}

/// The primary action button of the design system. Supports three variants
/// and an inline busy spinner that disables interaction while loading.
class NovaButton extends StatelessWidget {
  const NovaButton({
    required this.label,
    required this.onPressed,
    this.variant = NovaButtonVariant.primary,
    this.busy = false,
    this.icon,
    this.expand = true,
    super.key,
  });

  /// Shorthand for a primary button.
  const NovaButton.primary({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.expand = true,
    super.key,
  }) : variant = NovaButtonVariant.primary;

  /// Shorthand for a secondary button.
  const NovaButton.secondary({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.expand = true,
    super.key,
  }) : variant = NovaButtonVariant.secondary;

  /// Shorthand for a ghost button.
  const NovaButton.ghost({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
    this.expand = true,
    super.key,
  }) : variant = NovaButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final NovaButtonVariant variant;
  final bool busy;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (bg, fg) = switch (variant) {
      NovaButtonVariant.primary => (AppColors.lime, AppColors.ink),
      NovaButtonVariant.secondary => (AppColors.deepInk, AppColors.lime),
      NovaButtonVariant.ghost => (Colors.transparent, colors.textPrimary),
    };

    final effectiveOnPressed = busy ? null : onPressed;

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) && !busy
            ? bg.withValues(alpha: .45)
            : bg,
      ),
      foregroundColor: WidgetStateProperty.all(fg),
      minimumSize: WidgetStateProperty.all(
        Size(expand ? double.infinity : 0, 54),
      ),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: variant == NovaButtonVariant.ghost
              ? BorderSide(color: colors.border, width: 1.4)
              : BorderSide.none,
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      overlayColor: WidgetStateProperty.all(
        fg.withValues(alpha: .08),
      ),
    );

    final child = busy
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    return TextButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );
  }
}
