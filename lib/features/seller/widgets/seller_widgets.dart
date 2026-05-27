import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../design/design_system.dart';
import '../../../design/components/nova_image.dart';

/// Shared visual building blocks for the WS7 seller suite.

/// Shows a transient confirmation message at the bottom of the screen.
void showSellerSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? AppColors.danger : AppColors.deepInk,
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.surface,
          ),
        ),
      ),
    );
}

/// A compact metric card: a tinted icon, a value and a label.
class SellerStatCard extends StatelessWidget {
  const SellerStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// A large tappable action tile used in quick-action grids.
class SellerActionTile extends StatelessWidget {
  const SellerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tintColor = tint ?? colors.surfaceMuted;
    // Pick a legible icon colour for whatever tint was given.
    final iconColor =
        tintColor.computeLuminance() > 0.5 ? AppColors.ink : colors.textPrimary;
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: tintColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded section card with a title and an arbitrary body.
class SellerPanel extends StatelessWidget {
  const SellerPanel({
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: context.colors.textPrimary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// A thumbnail showing either picked bytes, a remote URL or a placeholder.
class SellerImagePreview extends StatelessWidget {
  const SellerImagePreview({
    this.bytes,
    this.url,
    this.aspectRatio = 1.5,
    this.placeholderLabel = 'Aperçu de la photo',
    super.key,
  });

  final Uint8List? bytes;
  final String? url;
  final double aspectRatio;
  final String placeholderLabel;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (bytes != null) {
      content = Image.memory(bytes!, fit: BoxFit.cover);
    } else if ((url ?? '').isNotEmpty) {
      content = NovaImage(
        url: url,
        fit: BoxFit.cover,
        placeholder: const ColoredBox(color: AppColors.butter),
        error: const _SellerImagePlaceholder(label: 'Image introuvable'),
      );
    } else {
      content = _SellerImagePlaceholder(label: placeholderLabel);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AspectRatio(aspectRatio: aspectRatio, child: content),
    );
  }
}

class _SellerImagePlaceholder extends StatelessWidget {
  const _SellerImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceMuted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 38,
            color: colors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A dark, highlighted info banner.
class SellerInfoBanner extends StatelessWidget {
  const SellerInfoBanner({
    required this.icon,
    required this.message,
    this.color = AppColors.deepInk,
    this.textColor = Colors.white,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color textColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: textColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A simple labelled key/value row.
class SellerDetailRow extends StatelessWidget {
  const SellerDetailRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
