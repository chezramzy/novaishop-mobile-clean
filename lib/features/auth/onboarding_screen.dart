import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../design/design_system.dart';
import 'widgets/auth_scaffold.dart';

/// The first-run onboarding carousel introducing the marketplace.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      icon: Icons.inventory_2_rounded,
      accent: AppColors.lavender,
      title: 'Un catalogue unifie',
      body: 'Une seule experience NovaShop pour explorer produits, variantes '
          'et disponibilites.',
    ),
    _OnboardingSlide(
      icon: Icons.chat_bubble_outline_rounded,
      accent: AppColors.butter,
      title: 'Commandez par message',
      body: 'Votre panier ouvre une conversation NovaShop jusqu a la '
          'livraison et sa confirmation.',
    ),
    _OnboardingSlide(
      icon: Icons.local_shipping_rounded,
      accent: AppColors.blush,
      title: 'Une livraison suivie',
      body: 'Nos livreurs apportent chaque commande à votre porte, avec un '
          'suivi en temps réel à chaque étape.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() => _controller.animateToPage(
        _slides.length - 1,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );

  void _next() {
    if (_isLast) {
      Navigator.of(context).pushNamed(RouteNames.roleSelection);
    } else {
      _controller.nextPage(
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: AppColors.deepInk,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.lime,
                    size: 20,
                  ),
                ),
                AppSpacing.hGapSm,
                Text('NovAiShop', style: AppTypography.title),
                const Spacer(),
                AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: _isLast ? 0 : 1,
                  child: TextButton(
                    onPressed: _isLast ? null : _skip,
                    child: Text(
                      'Passer',
                      style: AppTypography.body.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ).fadeSlideIn(),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (_, index) =>
                    _SlideView(slide: _slides[index], active: index == _page),
              ),
            ),
            AppSpacing.gapXs,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < _slides.length; index++)
                  AnimatedContainer(
                    duration: AppMotion.normal,
                    curve: AppMotion.standard,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 7,
                    width: index == _page ? 24 : 7,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? context.colors.textPrimary
                          : context.colors.textPrimary.withValues(alpha: .18),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
              ],
            ),
            AppSpacing.gapXl,
            NovaButton.primary(
              label: _isLast ? 'Créer votre compte' : 'Suivant',
              icon: _isLast ? Icons.arrow_forward_rounded : null,
              onPressed: _next,
            ),
            AppSpacing.gapXs,
            AuthFooterLink(
              leading: 'Déjà membre ?',
              action: 'Se connecter',
              onTap: () => Navigator.of(context).pushNamed(RouteNames.signIn),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.active});

  final _OnboardingSlide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Center(
            child: AnimatedScale(
              duration: AppMotion.slow,
              curve: AppMotion.emphasized,
              scale: active ? 1 : 0.92,
              child: _Illustration(icon: slide.icon, accent: slide.accent),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted,
          ),
        ),
      ],
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      width: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .55),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            top: 14,
            right: 20,
            child: _Blob(color: accent, size: 46),
          ),
          Positioned(
            bottom: 22,
            left: 14,
            child:
                _Blob(color: AppColors.lime.withValues(alpha: .65), size: 32),
          ),
          Container(
            height: 158,
            width: 158,
            decoration: BoxDecoration(
              color: AppColors.deepInk,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.deepInk.withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(icon, size: 76, color: AppColors.lime),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
