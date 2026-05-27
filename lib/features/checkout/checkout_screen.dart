import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/address.dart';
import '../../data/models/coupon.dart';
import '../../data/repositories/address_repository.dart';
import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import 'checkout_flow.dart';
import 'payment_screen.dart';

/// The checkout screen: pick a delivery address, apply a coupon and review
/// an itemised order summary before paying.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<List<Address>> _addressesFuture;
  Address? _selected;

  final _couponController = TextEditingController();
  Timer? _couponDebounce;
  _CouponState _couponState = const _CouponState.idle();

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  @override
  void dispose() {
    _couponDebounce?.cancel();
    _couponController.dispose();
    super.dispose();
  }

  Future<List<Address>> _loadAddresses() async {
    final addresses = await context.read<AddressRepository>().getAddresses();
    final list = addresses;
    final current = _selected;
    if (list.isEmpty) {
      _selected = null;
    } else if (current == null || !list.any((a) => a.id == current.id)) {
      _selected = list.firstWhere(
        (a) => a.isDefault,
        orElse: () => list.first,
      );
    }
    return list;
  }

  void _reloadAddresses() {
    setState(() => _addressesFuture = _loadAddresses());
  }

  Future<void> _addAddress() async {
    await Navigator.of(context).pushNamed(RouteNames.addAddress);
    if (!mounted) return;
    _reloadAddresses();
  }

  void _onCouponChanged(String value) {
    _couponDebounce?.cancel();
    final code = value.trim();
    if (code.isEmpty) {
      setState(() => _couponState = const _CouponState.idle());
      return;
    }
    setState(() => _couponState = const _CouponState.validating());
    _couponDebounce = Timer(
      const Duration(milliseconds: 600),
      () => _validateCoupon(code),
    );
  }

  Future<void> _validateCoupon(String code) async {
    final cart = context.read<CartController>();
    try {
      final result = await context.read<CouponRepository>().validateCoupon(
            code: code,
            orderAmount: cart.subtotal,
          );
      if (!mounted || _couponController.text.trim() != code) return;
      setState(() => _couponState = _CouponState.resolved(result));
    } on RepositoryException catch (error) {
      if (!mounted || _couponController.text.trim() != code) return;
      setState(() => _couponState = _CouponState.error(error.message));
    } catch (_) {
      if (!mounted || _couponController.text.trim() != code) return;
      setState(
        () => _couponState = const _CouponState.error(
          'Impossible de vérifier ce code pour le moment.',
        ),
      );
    }
  }

  void _clearCoupon() {
    _couponDebounce?.cancel();
    _couponController.clear();
    setState(() => _couponState = const _CouponState.idle());
  }

  void _pickAddress(List<Address> addresses) {
    showNovaSheet<void>(
      context: context,
      title: 'Adresse de livraison',
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...addresses.map(
              (address) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _AddressOption(
                  address: address,
                  selected: address.id == _selected?.id,
                  onTap: () {
                    setState(() => _selected = address);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            NovaButton.secondary(
              label: 'Ajouter une adresse',
              icon: Icons.add_location_alt_outlined,
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _addAddress();
              },
            ),
          ],
        );
      },
    );
  }

  void _goToPayment() {
    final cart = context.read<CartController>();
    final address = _selected;
    if (address == null) return;

    final discount = _couponState.discount(cart.subtotal);
    final draft = CheckoutDraft(
      address: address,
      subtotal: cart.subtotal,
      shippingFee: shippingFeeFor(cart.subtotal),
      discount: discount,
      couponCode: _couponState.appliedCode,
      items: [
        for (final item in cart.items)
          (listingId: item.listing.id, quantity: item.quantity),
      ],
    );

    Navigator.of(context).push(
      AppPageRoute.sharedAxis(
        PaymentScreen(draft: draft),
        settings: const RouteSettings(name: RouteNames.payment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final isEmpty = cart.items.isEmpty;
    final subtotal = cart.subtotal;
    final shipping = shippingFeeFor(subtotal);
    final discount = _couponState.discount(subtotal);
    final total = (subtotal + shipping - discount).clamp(0, double.infinity);
    final isAuthenticated = context.watch<AuthController>().isAuthenticated;

    return SoftGradientScaffold(
      bottomNavigationBar: isEmpty
          ? null
          : _CheckoutBottomBar(
              total: total.toDouble(),
              canConfirm: _selected != null && isAuthenticated,
              onConfirm: _goToPayment,
              notice: isAuthenticated
                  ? null
                  : 'Connectez-vous pour finaliser votre commande.',
            ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: ScreenHeader(title: 'Commande'),
          ),
          Expanded(
            child: isEmpty
                ? NovaEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Aucun article à commander',
                    message: 'Ajoutez des produits à votre panier avant '
                        'de passer commande.',
                    actionLabel: 'Retour',
                    onAction: () => Navigator.of(context).maybePop(),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    children: [
                      const _SectionLabel(
                        icon: Icons.local_shipping_outlined,
                        label: 'Livraison',
                      ).fadeSlideIn(),
                      AppSpacing.gapSm,
                      FutureBuilder<List<Address>>(
                        future: _addressesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
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
                                message: 'Impossible de charger vos '
                                    'adresses.',
                                onRetry: _reloadAddresses,
                              ),
                            );
                          }
                          final addresses = snapshot.data ?? const [];
                          if (addresses.isEmpty || _selected == null) {
                            return _AddAddressCard(onAdd: _addAddress);
                          }
                          return _SelectedAddressCard(
                            address: _selected!,
                            onChange: () => _pickAddress(addresses),
                          ).fadeSlideIn();
                        },
                      ),
                      AppSpacing.gapLg,
                      const _SectionLabel(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Code promo',
                      ).fadeSlideIn(delay: AppMotion.stagger),
                      AppSpacing.gapSm,
                      _CouponField(
                        controller: _couponController,
                        state: _couponState,
                        onChanged: _onCouponChanged,
                        onClear: _clearCoupon,
                      ).fadeSlideIn(delay: AppMotion.stagger),
                      AppSpacing.gapLg,
                      const _SectionLabel(
                        icon: Icons.receipt_long_outlined,
                        label: 'Récapitulatif',
                      ).fadeSlideIn(delay: AppMotion.stagger * 2),
                      AppSpacing.gapSm,
                      _OrderSummaryCard(
                        cart: cart,
                        subtotal: subtotal,
                        shipping: shipping,
                        discount: discount,
                        total: total.toDouble(),
                      ).fadeSlideIn(delay: AppMotion.stagger * 2),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- coupon state ---------------------------- */

/// The four states a coupon field can be in.
enum _CouponPhase { idle, validating, resolved, error }

class _CouponState {
  const _CouponState._(
    this.phase, {
    this.result,
    this.errorMessage,
  });

  const _CouponState.idle() : this._(_CouponPhase.idle);
  const _CouponState.validating() : this._(_CouponPhase.validating);
  const _CouponState.resolved(CouponValidationResult result)
      : this._(_CouponPhase.resolved, result: result);
  const _CouponState.error(String message)
      : this._(_CouponPhase.error, errorMessage: message);

  final _CouponPhase phase;
  final CouponValidationResult? result;
  final String? errorMessage;

  bool get isValid => phase == _CouponPhase.resolved && result?.valid == true;

  String? get appliedCode => isValid ? result?.coupon?.code : null;

  double discount(double subtotal) {
    final value = result;
    if (!isValid || value == null) return 0;
    return discountFromCoupon(value, subtotal);
  }
}

/* -------------------------------- bottom bar ----------------------------- */

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.total,
    required this.canConfirm,
    required this.onConfirm,
    this.notice,
  });

  final double total;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final String? notice;

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
                    'Total à payer',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatPrice(total),
                    style: AppTypography.price.copyWith(fontSize: 22),
                  ),
                ],
              ),
              if (notice != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notice!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              NovaButton.primary(
                label: 'Procéder au paiement',
                icon: Icons.lock_outline_rounded,
                onPressed: canConfirm ? onConfirm : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------- sections ------------------------------- */

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.textPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SelectedAddressCard extends StatelessWidget {
  const _SelectedAddressCard({required this.address, required this.onChange});

  final Address address;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onChange,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: context.colors.lavender,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.place_outlined,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const NovaBadge(
                        label: 'Par défaut',
                        tone: NovaBadgeTone.primary,
                        dense: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.phone,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _AddAddressCard extends StatelessWidget {
  const _AddAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onAdd,
      color: context.colors.surfaceMuted,
      child: Row(
        children: [
          Icon(Icons.add_location_alt_outlined,
              color: context.colors.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Ajouter une adresse de livraison',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _AddressOption extends StatelessWidget {
  const _AddressOption({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      border: Border.all(
        color: selected ? context.colors.textPrimary : context.colors.border,
        width: selected ? 1.6 : 1,
      ),
      elevated: false,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? context.colors.textPrimary : AppColors.muted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  address.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
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

/* -------------------------------- coupon field --------------------------- */

class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.controller,
    required this.state,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final _CouponState state;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NovaTextField(
            controller: controller,
            label: 'Saisissez votre code',
            hint: 'Ex. BIENVENUE10',
            icon: Icons.local_offer_outlined,
            textCapitalization: TextCapitalization.characters,
            onChanged: onChanged,
            suffix: _suffix(context),
          ),
          if (state.phase != _CouponPhase.idle) ...[
            const SizedBox(height: AppSpacing.xs),
            _feedback(),
          ],
        ],
      ),
    );
  }

  Widget? _suffix(BuildContext context) {
    switch (state.phase) {
      case _CouponPhase.validating:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: context.colors.textPrimary,
            ),
          ),
        );
      case _CouponPhase.idle:
        return null;
      case _CouponPhase.resolved:
      case _CouponPhase.error:
        return IconButton(
          onPressed: onClear,
          tooltip: 'Effacer',
          icon: const Icon(Icons.close_rounded, size: 18),
        );
    }
  }

  Widget _feedback() {
    switch (state.phase) {
      case _CouponPhase.idle:
      case _CouponPhase.validating:
        return const SizedBox.shrink();
      case _CouponPhase.error:
        return _Banner(
          icon: Icons.error_outline_rounded,
          color: AppColors.danger,
          message: state.errorMessage ?? 'Code promo invalide.',
        );
      case _CouponPhase.resolved:
        final result = state.result;
        if (result == null || !result.valid) {
          return _Banner(
            icon: Icons.error_outline_rounded,
            color: AppColors.danger,
            message: result?.message.isNotEmpty == true
                ? result!.message
                : 'Ce code promo n’est pas valide.',
          );
        }
        final amount = result.discountAmount ?? 0;
        return _Banner(
          icon: Icons.check_circle_outline_rounded,
          color: AppColors.success,
          message: amount > 0
              ? 'Code appliqué : ${formatPrice(amount)} de remise.'
              : (result.message.isNotEmpty
                  ? result.message
                  : 'Code promo appliqué.'),
        );
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).fadeSlideIn(duration: AppMotion.fast);
  }
}

/* ------------------------------ order summary ---------------------------- */

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.cart,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
  });

  final CartController cart;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.listing.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    formatPrice(item.total),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(label: 'Sous-total', value: formatPrice(subtotal)),
          _SummaryRow(
            label: 'Livraison',
            value: shipping <= 0 ? 'Offerte' : formatPrice(shipping),
            highlight: shipping <= 0,
          ),
          if (discount > 0)
            _SummaryRow(
              label: 'Remise',
              value: '-${formatPrice(discount)}',
              highlight: true,
            ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            label: 'Total',
            value: formatPrice(total),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final valueColor =
        highlight ? AppColors.success : context.colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
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
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
