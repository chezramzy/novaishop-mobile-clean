import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import '../tokens/nova_colors.dart';

/// A simple centred loading spinner with an optional label. Prefer the
/// skeleton loaders for list/grid content; use this for short, blocking
/// waits (form submission, one-off fetches).
class NovaLoadingView extends StatelessWidget {
  const NovaLoadingView({this.label, super.key});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            width: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: colors.textPrimary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              label!,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
