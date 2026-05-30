import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../../design/design_system.dart';
import 'widgets/auth_scaffold.dart';

/// Step 1 of registration: pick how the user takes part in the marketplace.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  AccountRole? _selected;
  static const _publicRoles = [
    AccountRole.individualBuyer,
    AccountRole.wholesaleBuyer,
    AccountRole.deliveryPartner,
  ];

  void _continue() {
    final role = _selected;
    if (role == null) return;
    Navigator.of(context).pushNamed(RouteNames.signUp, arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              0,
            ),
            child: AuthIntro(
              title: 'Comment utiliserez-vous NovaShop ?',
              subtitle:
                  'Choisissez le profil qui vous correspond. Vous pourrez '
                  'en demander un autre plus tard depuis votre compte.',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                for (var i = 0; i < _publicRoles.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _RoleCard(
                      role: _publicRoles[i],
                      selected: _selected == _publicRoles[i],
                      onTap: () => setState(
                        () => _selected = _publicRoles[i],
                      ),
                    ).fadeSlideIn(
                      delay: AppMotion.stagger * i +
                          const Duration(milliseconds: 120),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xxs,
              AppSpacing.lg,
              AppSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Row(
              children: [
                const AuthStepIndicator(current: 0),
                const Spacer(),
                SizedBox(
                  width: 180,
                  child: NovaButton.primary(
                    label: 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _selected == null ? null : _continue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final AccountRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? AppColors.lime.withValues(alpha: .22) : colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? AppColors.lime : colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.deepInk : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  role.icon,
                  color: selected ? AppColors.lime : colors.textPrimary,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            role.label,
                            style: AppTypography.subtitle,
                          ),
                        ),
                        if (role.requiresBusinessName) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const NovaBadge(
                            label: 'Vérifié',
                            tone: NovaBadgeTone.primary,
                            dense: true,
                            icon: Icons.verified_rounded,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.description,
                      style: AppTypography.caption.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AnimatedContainer(
                duration: AppMotion.fast,
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.lime : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.lime : AppColors.muted,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: AppColors.ink,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
