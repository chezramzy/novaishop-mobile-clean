import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../tokens/nova_colors.dart';

/// A section title with an optional trailing action (e.g. "Voir tout").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel = AppStrings.seeAll,
    this.onAction,
    super.key,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
      ],
    );
  }
}
