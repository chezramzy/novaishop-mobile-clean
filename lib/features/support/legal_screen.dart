import 'package:flutter/material.dart';

import '../../design/design_system.dart';
import 'support_content.dart';
import 'support_screen.dart';

/// Affiche un document légal statique (mentions, confidentialité, CGU).
class LegalScreen extends StatelessWidget {
  const LegalScreen({this.topic = LegalTopic.notice, super.key});

  final LegalTopic topic;

  @override
  Widget build(BuildContext context) {
    final LegalDocument doc = topic.document;

    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
        children: [
          ScreenHeader(title: doc.title),
          const SizedBox(height: AppSpacing.lg),
          NovaCard(
            color: context.colors.lavender,
            elevated: false,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: context.colors.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    doc.intro,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.colors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ).fadeSlideIn(),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < doc.sections.length; i++) ...[
            StaggeredEntrance.item(
              i,
              NovaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 24,
                          width: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            doc.sections[i].title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      doc.sections[i].body,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const SizedBox(height: AppSpacing.sm),
          const Center(
            child: Text(
              'Dernière mise à jour : mai 2026',
              style: TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}
