import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../design/design_system.dart';
import 'order_status.dart';

/// Détail d'une commande : articles, totaux, suivi et actions.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<Order?> _future;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Order?> _load() {
    return context.read<OrderRepository>().getOrder(widget.orderId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _confirmCancel(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Annuler la commande ?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Cette commande sera annulée. Cette action est irréversible.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Conserver',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _cancelled = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Commande annulée.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<Order?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _DetailShell(child: NovaLoadingView());
          }
          if (snapshot.hasError) {
            return _DetailShell(
              child: NovaErrorState(
                message: snapshot.error.toString(),
                onRetry: _reload,
              ),
            );
          }
          final order = snapshot.data;
          if (order == null) {
            return const _DetailShell(
              child: NovaEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Commande introuvable',
                message: 'Cette commande n\'existe plus ou a été supprimée.',
              ),
            );
          }
          return _OrderDetailView(
            order: order,
            cancelled: _cancelled,
            onCancel: () => _confirmCancel(order),
          );
        },
      ),
    );
  }
}

/// En-tête + corps centré pour les états transitoires.
class _DetailShell extends StatelessWidget {
  const _DetailShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: ScreenHeader(title: 'Détail de la commande'),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({
    required this.order,
    required this.cancelled,
    required this.onCancel,
  });

  final Order order;
  final bool cancelled;
  final VoidCallback onCancel;

  String get _effectiveStatus => cancelled ? 'cancelled' : order.status;

  @override
  Widget build(BuildContext context) {
    final stepIndex = OrderStatusX.stepIndex(_effectiveStatus);
    final canCancel = !cancelled && OrderStatusX.canCancel(order.status);
    final shipping = order.total - order.subtotal - order.commissionTotal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: StaggeredEntrance.all([
        const ScreenHeader(title: 'Détail de la commande'),
        const SizedBox(height: 18),

        // ---------- summary card ----------
        NovaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Commande #${OrderStatusX.shortId(order.id)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  NovaStatusBadge(status: _effectiveStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Passée le ${OrderStatusX.formatDate(order.createdAt)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------- tracking number ----------
        if (order.trackingNumber != null &&
            order.trackingNumber!.isNotEmpty) ...[
          NovaCard(
            color: AppColors.deepInk,
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.qr_code_2_rounded, color: AppColors.ink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numéro de suivi',
                        style: TextStyle(
                          color: AppColors.lime,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.trackingNumber!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ---------- items ----------
        const _SectionTitle('Articles'),
        const SizedBox(height: 8),
        NovaCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.colors.border),
                _OrderItemRow(item: order.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------- totals ----------
        const _SectionTitle('Récapitulatif'),
        const SizedBox(height: 8),
        NovaCard(
          child: Column(
            children: [
              _TotalRow(label: 'Sous-total', value: order.subtotal),
              if (order.commissionTotal > 0) ...[
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'Frais de service',
                  value: order.commissionTotal,
                ),
              ],
              if (shipping > 0.001) ...[
                const SizedBox(height: 8),
                _TotalRow(label: 'Livraison', value: shipping),
              ],
              const SizedBox(height: 10),
              Divider(height: 1, color: context.colors.border),
              const SizedBox(height: 10),
              _TotalRow(
                label: 'Total',
                value: order.total,
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ---------- timeline ----------
        const _SectionTitle('Suivi'),
        const SizedBox(height: 8),
        NovaCard(
          child: _MiniTimeline(
            currentStep: stepIndex,
            cancelled: cancelled || OrderStatusX.isCancelled(order.status),
          ),
        ),
        const SizedBox(height: 20),

        // ---------- actions ----------
        if (stepIndex >= 0)
          NovaButton.primary(
            label: 'Suivre la livraison',
            icon: Icons.local_shipping_outlined,
            onPressed: () => Navigator.of(context).pushNamed(
              RouteNames.orderTracking,
              arguments: order.id,
            ),
          ),
        if (canCancel) ...[
          const SizedBox(height: 10),
          NovaButton.ghost(
            label: 'Annuler la commande',
            icon: Icons.cancel_outlined,
            onPressed: onCancel,
          ),
        ],
      ]),
    );
  }
}

/* ----------------------------- sub widgets ---------------------------- */

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.image_outlined,
                color: context.colors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quantité : ${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatPrice(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized ? context.colors.textPrimary : AppColors.muted,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
            fontSize: emphasized ? 15 : 13.5,
          ),
        ),
        const Spacer(),
        Text(
          formatPrice(value),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: emphasized ? 16 : 13.5,
          ),
        ),
      ],
    );
  }
}

/// Une frise verticale compacte du parcours de livraison.
class _MiniTimeline extends StatelessWidget {
  const _MiniTimeline({required this.currentStep, required this.cancelled});

  final int currentStep;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    if (cancelled) {
      return const Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.danger),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cette commande a été annulée. Aucun suivi disponible.',
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      );
    }

    const steps = OrderStatusX.steps;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            done: i <= currentStep,
            active: i == currentStep,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.done,
    required this.active,
    required this.isLast,
  });

  final OrderStep step;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: done ? AppColors.lime : context.colors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: context.colors.textPrimary, width: 2)
                      : null,
                ),
                child: Icon(
                  done ? Icons.check_rounded : step.icon,
                  size: 16,
                  color: done ? AppColors.ink : AppColors.muted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.lime : context.colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color:
                          done ? context.colors.textPrimary : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
