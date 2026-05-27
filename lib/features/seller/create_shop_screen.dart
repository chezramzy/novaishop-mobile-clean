import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../data/models/seller_dashboard.dart';
import '../../design/design_system.dart';

class CreateShopScreen extends StatelessWidget {
  const CreateShopScreen({this.existing, super.key});

  final SellerDashboardSummary? existing;

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          const ScreenHeader(title: 'Espace partenaire'),
          const SizedBox(height: AppSpacing.lg),
          NovaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 36),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun profil public a configurer',
                  style: AppTypography.title.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Les partenaires alimentent le catalogue NovaShop en prive. '
                  'Vous pouvez directement ajouter et gerer vos produits.',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                NovaButton.primary(
                  label: 'Aller a mes produits',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(RouteNames.partnerHome),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
