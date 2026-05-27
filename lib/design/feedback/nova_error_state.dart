import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../components/nova_button.dart';
import '../motion/animations.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// The error state: an icon, the error message and a "Réessayer" button.
class NovaErrorState extends StatelessWidget {
  const NovaErrorState({
    required this.message,
    required this.onRetry,
    this.title = AppStrings.errorTitle,
    this.icon = Icons.cloud_off_rounded,
    this.retryLabel = AppStrings.retry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;
  final IconData icon;
  final String retryLabel;

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
              child: Icon(icon, size: 40, color: AppColors.danger),
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
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 220,
              child: NovaButton.primary(
                label: retryLabel,
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ).fadeSlideIn(),
    );
  }
}
