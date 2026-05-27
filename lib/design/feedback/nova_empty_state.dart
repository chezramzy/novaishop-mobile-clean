import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../components/nova_button.dart';
import '../motion/animations.dart';
import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// The empty-data state: an icon, a title, an explanatory message and an
/// optional call-to-action button.
class NovaEmptyState extends StatelessWidget {
  const NovaEmptyState({
    this.icon = Icons.inbox_outlined,
    this.title = AppStrings.emptyTitle,
    this.message = AppStrings.emptyMessage,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(icon, size: 40, color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: 220,
                child: NovaButton.primary(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ).fadeSlideIn(),
    );
  }
}
