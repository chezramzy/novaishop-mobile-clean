import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'widgets/seller_widgets.dart';

/// Arguments for the seller order-detail route.
class SellerOrderDetailArgs {
  const SellerOrderDetailArgs({required this.order, required this.vendorId});

  final Order order;
  final String vendorId;
}

/// Shows the full detail of one seller order and lets the seller advance
/// its status (pending -> paid -> processing -> shipped -> delivered).
class SellerOrderDetailScreen extends StatefulWidget {
  const SellerOrderDetailScreen({required this.args, super.key});

  final SellerOrderDetailArgs args;

  @override
  State<SellerOrderDetailScreen> createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  late Order _order;
  bool _busy = false;
  bool _changed = false;

  /// Forward status flow for a seller-managed order.
  static const _flow = <String>[
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.args.order;
  }

  String? get _nextStatus {
    final index = _flow.indexOf(_order.status);
    if (index < 0 || index >= _flow.length - 1) return null;
    return _flow[index + 1];
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payée';
      case 'processing':
        return 'En préparation';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      case 'refunded':
        return 'Remboursée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _actionLabel(String next) {
    switch (next) {
      case 'paid':
        return 'Marquer comme payée';
      case 'processing':
        return 'Commencer la préparation';
      case 'shipped':
        return 'Marquer comme expédiée';
      case 'delivered':
        return 'Marquer comme livrée';
      default:
        return 'Passer à « ${_statusLabel(next)} »';
    }
  }

  Future<void> _advance() async {
    final next = _nextStatus;
    if (next == null || _busy) return;

    final repository = SellerRepository(
      accessToken: context.read<AuthController>().accessToken,
    );

    String? trackingNumber;
    if (next == 'shipped') {
      trackingNumber = await _askTrackingNumber();
      if (trackingNumber == null) return;
    }

    setState(() => _busy = true);
    try {
      final updated = await repository.updateOrderStatus(
        widget.args.vendorId,
        _order.id,
        status: next,
        trackingNumber: trackingNumber,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _changed = true;
      });
      showSellerSnack(
        context,
        'Statut mis à jour : ${_statusLabel(next)}.',
      );
    } on RepositoryException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSellerSnack(
          context,
          'Mise à jour impossible. Réessayez.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askTrackingNumber() {
    final controller = TextEditingController(
      text: _order.trackingNumber ?? '',
    );
    return showNovaSheet<String>(
      context: context,
      title: 'Numéro de suivi',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Saisissez le numéro de suivi du transporteur. Le client en '
            'sera informé par e-mail.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          NovaTextField(
            controller: controller,
            label: 'Numéro de suivi',
            hint: 'Ex. LP00123456789',
            icon: Icons.local_shipping_outlined,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: 'Confirmer l\'expédition',
            icon: Icons.check_rounded,
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                showSellerSnack(
                  sheetContext,
                  'Saisissez un numéro de suivi.',
                  error: true,
                );
                return;
              }
              Navigator.of(sheetContext).pop(value);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortId =
        _order.id.length > 8 ? _order.id.substring(0, 8) : _order.id;
    final next = _nextStatus;
    final terminal = _order.status == 'refunded' ||
        _order.status == 'cancelled' ||
        _order.status == 'delivered';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: SoftGradientScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: StaggeredEntrance.all([
            ScreenHeader(
              title: 'Commande #$shortId',
              onBack: () => Navigator.of(context).pop(_changed),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatusTimeline(current: _order.status),
            const SizedBox(height: AppSpacing.md),
            SellerPanel(
              title: 'Articles',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  for (final item in _order.items) _OrderItemRow(item: item),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SellerPanel(
              title: 'Récapitulatif',
              icon: Icons.summarize_outlined,
              child: Column(
                children: [
                  SellerDetailRow(
                    label: 'Sous-total',
                    value: formatPrice(_order.subtotal),
                  ),
                  SellerDetailRow(
                    label: 'Commission',
                    value: '- ${formatPrice(_order.commissionTotal)}',
                  ),
                  Divider(color: context.colors.border),
                  SellerDetailRow(
                    label: 'Total client',
                    value: formatPrice(_order.total),
                  ),
                  if ((_order.trackingNumber ?? '').isNotEmpty)
                    SellerDetailRow(
                      label: 'Suivi',
                      value: _order.trackingNumber!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (next != null)
              NovaButton.primary(
                label: _actionLabel(next),
                icon: Icons.arrow_forward_rounded,
                busy: _busy,
                onPressed: _advance,
              )
            else if (terminal)
              const SellerInfoBanner(
                icon: Icons.check_circle_outline_rounded,
                message: 'Cette commande est clôturée.',
              ),
          ]),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.current});

  final String current;

  static const _steps = <(String, String, IconData)>[
    ('pending', 'En attente', Icons.hourglass_empty_rounded),
    ('paid', 'Payée', Icons.credit_card_rounded),
    ('processing', 'Préparation', Icons.inventory_2_outlined),
    ('shipped', 'Expédiée', Icons.local_shipping_outlined),
    ('delivered', 'Livrée', Icons.check_circle_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (current == 'refunded' || current == 'cancelled') {
      return SellerInfoBanner(
        icon: current == 'refunded'
            ? Icons.replay_circle_filled_outlined
            : Icons.cancel_outlined,
        color: AppColors.danger,
        message: current == 'refunded'
            ? 'Cette commande a été remboursée.'
            : 'Cette commande a été annulée.',
      );
    }
    final currentIndex =
        _steps.indexWhere((step) => step.$1 == current).clamp(0, 4);
    return NovaCard(
      child: Row(
        children: [
          for (var i = 0; i < _steps.length; i++) ...[
            _TimelineNode(
              icon: _steps[i].$3,
              label: _steps[i].$2,
              done: i <= currentIndex,
              active: i == currentIndex,
            ),
            if (i < _steps.length - 1)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 18),
                  color:
                      i < currentIndex ? AppColors.lime : context.colors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.icon,
    required this.label,
    required this.done,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotion.normal,
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: done ? AppColors.lime : context.colors.surfaceMuted,
              shape: BoxShape.circle,
              border: active
                  ? Border.all(color: context.colors.textPrimary, width: 2)
                  : null,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              size: 16,
              color: done ? AppColors.ink : context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              color: done ? context.colors.textPrimary : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'x${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            formatPrice(item.totalPrice),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
