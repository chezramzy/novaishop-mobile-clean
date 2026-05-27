import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'support_content.dart';

/// Foire aux questions : thèmes et entrées repliables.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themes = SupportContent.faq.entries.toList();

    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const ScreenHeader(title: 'Questions fréquentes'),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < themes.length; i++) ...[
            StaggeredEntrance.item(
              i,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      themes[i].key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppColors.muted,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                  NovaCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Column(
                      children: [
                        for (final entry in themes[i].value)
                          _FaqItem(entry: entry),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          NovaCard(
            color: context.colors.surfaceMuted,
            elevated: false,
            child: Column(
              children: [
                const Text(
                  'Vous n’avez pas trouvé votre réponse ?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                NovaButton.primary(
                  label: 'Contacter le support',
                  icon: Icons.headset_mic_rounded,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.contact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({required this.entry});

  final FaqEntry entry;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: AppMotion.fast,
                  child: const Icon(Icons.expand_more_rounded,
                      color: AppColors.muted),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: AppMotion.normal,
              firstCurve: AppMotion.standard,
              secondCurve: AppMotion.standard,
              sizeCurve: AppMotion.standard,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  widget.entry.answer,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
