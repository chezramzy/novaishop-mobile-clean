import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'support_content.dart';

/// Centre d'aide : accès à la FAQ, au contact et aux documents légaux.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const ScreenHeader(title: 'Aide & support'),
          const SizedBox(height: AppSpacing.lg),
          NovaCard(
            color: AppColors.deepInk,
            child: Row(
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: AppColors.ink),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment pouvons-nous vous aider ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Notre équipe est à votre écoute 7j/7.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).fadeSlideIn(),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Obtenir de l’aide'),
          const SizedBox(height: AppSpacing.sm),
          _SupportTile(
            icon: Icons.quiz_rounded,
            title: 'Questions fréquentes',
            subtitle: 'Trouvez une réponse immédiate',
            onTap: () => Navigator.of(context).pushNamed(RouteNames.faq),
          ).fadeSlideIn(delay: AppMotion.fast),
          const SizedBox(height: AppSpacing.xs),
          _SupportTile(
            icon: Icons.headset_mic_rounded,
            title: 'Nous contacter',
            subtitle: 'Échangez avec le support client',
            onTap: () => Navigator.of(context).pushNamed(RouteNames.contact),
          ).fadeSlideIn(delay: AppMotion.normal),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Partenaires'),
          const SizedBox(height: AppSpacing.sm),
          _SupportTile(
            icon: Icons.inventory_2_rounded,
            title: 'Proposer mes produits sur NovaShop',
            subtitle: 'Demander un espace partenaire discret',
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.partnerApplication),
          ).fadeSlideIn(delay: AppMotion.normal),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Informations légales'),
          const SizedBox(height: AppSpacing.sm),
          _SupportTile(
            icon: Icons.gavel_rounded,
            title: 'Mentions légales',
            subtitle: 'Éditeur et hébergement',
            onTap: () => Navigator.of(context).pushNamed(
              RouteNames.legal,
              arguments: LegalTopic.notice,
            ),
          ).fadeSlideIn(delay: AppMotion.normal),
          const SizedBox(height: AppSpacing.xs),
          _SupportTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Confidentialité',
            subtitle: 'Gestion de vos données personnelles',
            onTap: () => Navigator.of(context).pushNamed(
              RouteNames.legal,
              arguments: LegalTopic.privacy,
            ),
          ).fadeSlideIn(delay: AppMotion.normal),
          const SizedBox(height: AppSpacing.xs),
          _SupportTile(
            icon: Icons.description_rounded,
            title: 'Conditions d’utilisation',
            subtitle: 'Règles d’usage de la plateforme',
            onTap: () => Navigator.of(context).pushNamed(
              RouteNames.legal,
              arguments: LegalTopic.terms,
            ),
          ).fadeSlideIn(delay: AppMotion.slow),
          const SizedBox(height: AppSpacing.lg),
          const Center(
            child: Text(
              'NovAiShop · version 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

}

/// Le document légal demandé par l'écran [LegalScreen].
enum LegalTopic { notice, privacy, terms }

extension LegalTopicX on LegalTopic {
  LegalDocument get document {
    switch (this) {
      case LegalTopic.notice:
        return SupportContent.legalNotice;
      case LegalTopic.privacy:
        return SupportContent.privacyPolicy;
      case LegalTopic.terms:
        return SupportContent.termsOfUse;
    }
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, size: 20, color: context.colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
