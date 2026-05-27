import 'package:flutter/material.dart';

import '../../../design/design_system.dart';

/// A compact, animated header used at the top of every auth screen.
///
/// Replaces the legacy `AuthHeader` from `auth_widgets.dart` with a version
/// built on the design-system tokens and motion kit.
class AuthIntro extends StatelessWidget {
  const AuthIntro({
    required this.title,
    required this.subtitle,
    this.showBack = true,
    this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool showBack;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
          ).fadeSlideIn(),
        SizedBox(height: showBack ? AppSpacing.xl : 0),
        if (icon != null) ...[
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.deepInk,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.lime, size: 28),
          ).popIn(delay: AppMotion.fast),
          AppSpacing.gapMd,
        ],
        Text(
          title,
          style: AppTypography.headline.copyWith(height: 1.12),
        ).fadeSlideIn(delay: const Duration(milliseconds: 60)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTypography.bodyMuted,
        ).fadeSlideIn(delay: const Duration(milliseconds: 120)),
      ],
    );
  }
}

/// An animated progress indicator for the multi-step registration flow.
class AuthStepIndicator extends StatelessWidget {
  const AuthStepIndicator({
    required this.current,
    this.count = 3,
    super.key,
  });

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.textPrimary;
    return Row(
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            margin: const EdgeInsets.only(right: 6),
            height: 8,
            width: index == current ? 26 : 8,
            decoration: BoxDecoration(
              color: index <= current ? accent : accent.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
      ],
    );
  }
}

/// A tappable rich-text link row, e.g. "Déjà membre ? Se connecter".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.leading,
    required this.action,
    required this.onTap,
    super.key,
  });

  final String leading;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text.rich(
          TextSpan(
            style: AppTypography.bodyMuted,
            children: [
              TextSpan(text: '$leading  '),
              TextSpan(
                text: action,
                style: AppTypography.body.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a themed error message via [ScaffoldMessenger].
void showAuthMessage(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.deepInk,
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? AppColors.danger : AppColors.lime,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

/// The "Ou continuez avec" divider plus the social provider buttons.
class SocialAuthBlock extends StatelessWidget {
  const SocialAuthBlock({
    required this.onProvider,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onProvider;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colors.border;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: borderColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Ou continuez avec',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Divider(color: borderColor)),
          ],
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            _SocialButton(
              label: 'Google',
              icon: Icons.g_mobiledata_rounded,
              onTap: enabled ? () => onProvider('Google') : null,
            ),
            AppSpacing.hGapSm,
            _SocialButton(
              label: 'Apple',
              icon: Icons.apple_rounded,
              onTap: enabled ? () => onProvider('Apple') : null,
            ),
            AppSpacing.hGapSm,
            _SocialButton(
              label: 'Facebook',
              icon: Icons.facebook_rounded,
              onTap: enabled ? () => onProvider('Facebook') : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              children: [
                Icon(icon, size: 26, color: colors.textPrimary),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
