import 'package:flutter/material.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../design/design_system.dart';

/// The confirmation screen shown after a successful payment. Surfaces the
/// order number and total, and routes to order tracking or back to shopping.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    required this.orderNumber,
    required this.total,
    required this.itemCount,
    super.key,
  });

  final String orderNumber;
  final double total;
  final int itemCount;

  void _trackOrder(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteNames.orderTracking,
      arguments: orderNumber,
    );
  }

  void _continueShopping(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          children: [
            const Spacer(),
            _SuccessMark(),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Commande confirmée !',
              textAlign: TextAlign.center,
              style: AppTypography.headline,
            ).fadeSlideIn(delay: AppMotion.normal),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Merci pour votre achat. Votre commande est en préparation '
              'et vous recevrez bientôt un suivi de livraison.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ).fadeSlideIn(delay: AppMotion.normal),
            const SizedBox(height: AppSpacing.lg),
            NovaCard(
              child: Column(
                children: [
                  _Row(
                    label: 'Numéro de commande',
                    value: '#$orderNumber',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    label: 'Articles',
                    value: '$itemCount '
                        'article${itemCount > 1 ? 's' : ''}',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    label: 'Total payé',
                    value: formatPrice(total),
                    strong: true,
                  ),
                ],
              ),
            ).fadeSlideIn(delay: AppMotion.slow),
            const Spacer(),
            NovaButton.primary(
              label: 'Suivre ma commande',
              icon: Icons.local_shipping_outlined,
              onPressed: () => _trackOrder(context),
            ).fadeSlideIn(delay: AppMotion.slow),
            const SizedBox(height: AppSpacing.xs),
            NovaButton.ghost(
              label: 'Continuer mes achats',
              onPressed: () => _continueShopping(context),
            ).fadeSlideIn(delay: AppMotion.slow),
          ],
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: 112,
      decoration: const BoxDecoration(
        color: AppColors.lime,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 62,
        color: AppColors.ink,
      ),
    ).popIn(duration: AppMotion.slow);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: strong ? 18 : 14,
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
