import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/order.dart';
import '../../data/models/payment_record.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../payment/payment_method.dart';
import 'checkout_flow.dart';
import 'order_confirmation_screen.dart';

/// Legacy payment screen kept out of the production route table.
///
/// On confirm it runs the full API flow — create order → create intent →
/// confirm payment — then clears the cart and shows the confirmation.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({required this.draft, super.key});

  final CheckoutDraft draft;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PayPhase { idle, processing, failed }

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<List<PaymentMethod>> _methodsFuture;
  PaymentMethod? _selected;

  _PayPhase _phase = _PayPhase.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _methodsFuture = _loadMethods();
  }

  Future<List<PaymentMethod>> _loadMethods() async {
    final methods = await PaymentMethodStore.instance.getMethods();
    final current = _selected;
    if (methods.isNotEmpty &&
        (current == null || !methods.any((m) => m.id == current.id))) {
      _selected = methods.firstWhere(
        (m) => m.isDefault,
        orElse: () => methods.first,
      );
    }
    return methods;
  }

  void _reloadMethods() {
    setState(() => _methodsFuture = _loadMethods());
  }

  Future<void> _openMethods() async {
    await Navigator.of(context).pushNamed(RouteNames.paymentMethods);
    if (!mounted) return;
    _reloadMethods();
  }

  Future<void> _pay() async {
    final auth = context.read<AuthController>();
    setState(() {
      _phase = _PayPhase.processing;
      _errorMessage = null;
    });

    final orderRepo = OrderRepository(accessToken: auth.accessToken);
    final paymentRepo = PaymentRepository(accessToken: auth.accessToken);

    try {
      final Order order = await orderRepo.createOrder(widget.draft.items);
      final PaymentRecord intent = await paymentRepo.createIntent(order.id);
      final PaymentRecord confirmed =
          await paymentRepo.confirmPayment(intent.id);

      if (!mounted) return;

      if (!confirmed.isSucceeded) {
        setState(() {
          _phase = _PayPhase.failed;
          _errorMessage = 'Le paiement n’a pas pu être confirmé. '
              'Réessayez ou changez de moyen de paiement.';
        });
        return;
      }

      context.read<CartController>().clear();
      Navigator.of(context).pushReplacement(
        AppPageRoute.fade(
          OrderConfirmationScreen(
            orderNumber: order.id,
            total: confirmed.amount > 0 ? confirmed.amount : widget.draft.total,
            itemCount: widget.draft.items
                .fold<int>(0, (sum, item) => sum + item.quantity),
          ),
          settings: const RouteSettings(name: RouteNames.orderConfirmation),
        ),
      );
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.failed;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _PayPhase.failed;
        _errorMessage = 'Une erreur est survenue pendant le paiement. '
            'Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    final processing = _phase == _PayPhase.processing;

    return SoftGradientScaffold(
      bottomNavigationBar: _PaymentBottomBar(
        total: draft.total,
        busy: processing,
        enabled: _selected != null,
        onPay: _pay,
      ),
      child: AbsorbPointer(
        absorbing: processing,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: ScreenHeader(title: 'Paiement'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _AmountHeader(total: draft.total).fadeSlideIn(),
                  AppSpacing.gapLg,
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Moyen de paiement',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openMethods,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Gérer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.deepInk,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ).fadeSlideIn(delay: AppMotion.stagger),
                  AppSpacing.gapXs,
                  FutureBuilder<List<PaymentMethod>>(
                    future: _methodsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const NovaCard(
                          child: SizedBox(
                            height: 72,
                            child: NovaLoadingView(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return NovaCard(
                          child: NovaErrorState(
                            message: 'Impossible de charger vos moyens '
                                'de paiement.',
                            onRetry: _reloadMethods,
                          ),
                        );
                      }
                      final methods = snapshot.data ?? const [];
                      if (methods.isEmpty) {
                        return _NoMethodCard(onAdd: _openMethods)
                            .fadeSlideIn(delay: AppMotion.stagger);
                      }
                      return Column(
                        children: [
                          for (var i = 0; i < methods.length; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _MethodTile(
                                method: methods[i],
                                selected: methods[i].id == _selected?.id,
                                onTap: () => setState(
                                  () => _selected = methods[i],
                                ),
                              ).fadeSlideIn(
                                delay: AppMotion.stagger * (i + 1),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  AppSpacing.gapLg,
                  const Text(
                    'Récapitulatif',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ).fadeSlideIn(delay: AppMotion.stagger * 2),
                  AppSpacing.gapXs,
                  _RecapCard(draft: draft)
                      .fadeSlideIn(delay: AppMotion.stagger * 2),
                  if (_phase == _PayPhase.failed && _errorMessage != null) ...[
                    AppSpacing.gapMd,
                    _FailureBanner(
                      message: _errorMessage!,
                      onRetry: _pay,
                    ),
                  ],
                  if (processing) ...[
                    AppSpacing.gapLg,
                    const _ProcessingBanner(),
                  ],
                  AppSpacing.gapMd,
                  const _SecurityNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- amount --------------------------------- */

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          const Text(
            'Montant à régler',
            style: TextStyle(
              color: AppColors.lime,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatPrice(total),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- payment methods --------------------------- */

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NovaCard(
      onTap: onTap,
      elevated: false,
      border: Border.all(
        color: selected ? colors.textPrimary : colors.border,
        width: selected ? 1.6 : 1,
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: method.brand.tintOf(colors),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(method.brand.icon, color: colors.textPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.brand.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  method.masked,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? colors.textPrimary : AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _NoMethodCard extends StatelessWidget {
  const _NoMethodCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onAdd,
      color: context.colors.surfaceMuted,
      child: Row(
        children: [
          Icon(Icons.add_card_outlined, color: context.colors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Ajoutez un moyen de paiement pour continuer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

/* --------------------------------- recap --------------------------------- */

class _RecapCard extends StatelessWidget {
  const _RecapCard({required this.draft});

  final CheckoutDraft draft;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: context.colors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${draft.address.label} · ${draft.address.fullAddress}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          _RecapRow(label: 'Sous-total', value: formatPrice(draft.subtotal)),
          _RecapRow(
            label: 'Livraison',
            value: draft.shippingFee <= 0
                ? 'Offerte'
                : formatPrice(draft.shippingFee),
          ),
          if (draft.discount > 0)
            _RecapRow(
              label: draft.couponCode != null
                  ? 'Remise (${draft.couponCode})'
                  : 'Remise',
              value: '-${formatPrice(draft.discount)}',
            ),
          const Divider(height: AppSpacing.lg),
          _RecapRow(
            label: 'Total',
            value: formatPrice(draft.total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  const _RecapRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: strong ? context.colors.textPrimary : AppColors.muted,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                fontSize: strong ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: strong ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------- banners -------------------------------- */

class _ProcessingBanner extends StatelessWidget {
  const _ProcessingBanner();

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      color: context.colors.butter,
      child: Row(
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Paiement en cours… ne fermez pas cette page.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ).fadeSlideIn(duration: AppMotion.fast);
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      color: AppColors.blush,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NovaButton.secondary(
            label: 'Réessayer le paiement',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    ).fadeSlideIn(duration: AppMotion.fast);
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 14,
          color: AppColors.muted,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            'Paiement sécurisé — démonstration NovaShop.',
            style: AppTypography.caption,
          ),
        ),
      ],
    );
  }
}

/* ------------------------------- bottom bar ------------------------------ */

class _PaymentBottomBar extends StatelessWidget {
  const _PaymentBottomBar({
    required this.total,
    required this.busy,
    required this.enabled,
    required this.onPay,
  });

  final double total;
  final bool busy;
  final bool enabled;
  final VoidCallback onPay;

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
          child: NovaButton.primary(
            label: 'Payer ${formatPrice(total)}',
            icon: Icons.lock_outline_rounded,
            busy: busy,
            onPressed: enabled ? onPay : null,
          ),
        ),
      ),
    );
  }
}
