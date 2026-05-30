import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/conversation.dart';
import '../../data/repositories/message_repository.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../auth/auth_controller.dart';
import '../messages/order_conversation_screen.dart';
import 'cart_controller.dart';

/// The shopping cart: line items with quantity steppers, a live price
/// summary, an empty state and a call to action towards checkout.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final isEmpty = cart.items.isEmpty;

    return SoftGradientScaffold(
      bottomNavigationBar: isEmpty ? null : _CartBottomBar(cart: cart),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: ScreenHeader(
              title: 'Mon panier',
              trailing: isEmpty
                  ? null
                  : NovaBadge(
                      label: '${cart.count} article'
                          '${cart.count > 1 ? 's' : ''}',
                      tone: NovaBadgeTone.primary,
                    ).popIn(),
            ),
          ),
          Expanded(
            child: isEmpty
                ? _EmptyCart(
                    onBrowse: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _CartTile(
                        key: ValueKey(item.key),
                        item: item,
                      ).fadeSlideIn(
                        delay: AppMotion.stagger * index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- bottom bar ------------------------------ */

class _CartBottomBar extends StatelessWidget {
  const _CartBottomBar({required this.cart});

  final CartController cart;

  Future<void> _startConversation(BuildContext context) async {
    if (context.read<AuthController>().user == null) {
      Navigator.of(context).pushNamed(RouteNames.signIn);
      return;
    }

    try {
      final conversation =
          await context.read<MessageRepository>().startOrderConversation(
        items: [
          for (final item in cart.items)
            ConversationOrderItem(
              listingId: item.listing.id,
              title: item.listing.title,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.total,
              variantId: item.variant?.id,
              options: item.selectedOptions,
            ),
        ],
      );
      if (!context.mounted) return;
      cart.clear();
      Navigator.of(context).pushNamed(
        RouteNames.orderConversation,
        arguments: OrderConversationArgs(conversation: conversation),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible de demarrer la conversation.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14202623),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Sous-total',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(cart.subtotal),
                    style: AppTypography.price.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Frais de livraison et remises calculés à l’étape suivante.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              NovaButton.primary(
                label: 'Commander par message',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: () => _startConversation(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------- cart tile ------------------------------ */

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, super.key});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CartController>();
    return NovaCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: NovaImage(
              url: item.listing.displayImage,
              width: 76,
              height: 84,
              fit: BoxFit.cover,
              placeholder: const ColoredBox(color: AppColors.butter),
              error: const ColoredBox(
                color: AppColors.butter,
                child: Icon(Icons.image_outlined, size: 22),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatPrice(item.unitPrice)} l unite',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
                if (item.selectedOptions.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.selectedOptions.values.join(' / '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _QuantityStepper(
                      quantity: item.quantity,
                      onDecrease: () => controller.decrease(item.key),
                      onIncrease: () => controller.add(
                        item.listing,
                        variant: item.variant,
                        selectedOptions: item.selectedOptions,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatPrice(item.total),
                      style: AppTypography.price,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          IconButton(
            onPressed: () {
              controller.remove(item.key);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content:
                        Text('« ${item.listing.title} » retiré du panier.'),
                  ),
                );
            },
            visualDensity: VisualDensity.compact,
            tooltip: 'Retirer',
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact +/- quantity control used inside cart line items.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity <= 1 ? Icons.delete_outline_rounded : Icons.remove,
            onTap: onDecrease,
          ),
          AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: SizedBox(
              key: ValueKey(quantity),
              width: 30,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.deepInk,
          foregroundColor: AppColors.lime,
        ),
      ),
    );
  }
}

/* ------------------------------- empty state ----------------------------- */

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return NovaEmptyState(
      icon: Icons.shopping_bag_outlined,
      title: 'Votre panier est vide',
      message: 'Parcourez le catalogue et ajoutez vos articles préférés '
          'pour les retrouver ici.',
      actionLabel: 'Découvrir le catalogue',
      onAction: onBrowse,
    );
  }
}
