import 'package:flutter/material.dart';

import 'circle_icon_button.dart';

/// A centred screen title with an optional back button and trailing action.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    this.trailing,
    this.onBack,
    this.showBack = true,
    super.key,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          )
        else
          const SizedBox(width: 44),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        trailing ?? const SizedBox(width: 44),
      ],
    );
  }
}
