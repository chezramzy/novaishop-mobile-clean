import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../design/design_system.dart';
import 'order_status.dart';

/// Suivi animé d'une commande : frise des étapes de livraison.
class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({required this.orderId, super.key});

  final String orderId;

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  late Future<Order?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderRepository>().getOrder(widget.orderId);
  }

  void _reload() {
    setState(() {
      _future = context.read<OrderRepository>().getOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Suivi de commande'),
          ),
          Expanded(
            child: FutureBuilder<Order?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const NovaLoadingView();
                }
                if (snapshot.hasError) {
                  return NovaErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                final order = snapshot.data;
                if (order == null) {
                  return const NovaEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Suivi indisponible',
                    message: 'Cette commande est introuvable.',
                  );
                }
                return _TrackerView(order: order);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerView extends StatelessWidget {
  const _TrackerView({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final cancelled = OrderStatusX.isCancelled(order.status);
    final currentStep = OrderStatusX.stepIndex(order.status);
    const steps = OrderStatusX.steps;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ---------- header card ----------
        _HeaderCard(order: order, cancelled: cancelled).fadeSlideIn(),
        const SizedBox(height: 22),

        if (cancelled)
          NovaCard(
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined,
                      color: AppColors.danger),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cette commande a été annulée. Le suivi de livraison '
                    'n\'est plus disponible.',
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ).fadeSlideIn(delay: AppMotion.fast)
        else
          for (var i = 0; i < steps.length; i++)
            _TrackerStep(
              step: steps[i],
              index: i,
              done: i <= currentStep,
              active: i == currentStep,
              isLast: i == steps.length - 1,
            ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order, required this.cancelled});

  final Order order;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final currentStep = OrderStatusX.stepIndex(order.status);
    final total = OrderStatusX.steps.length;
    final progress =
        cancelled ? 0.0 : ((currentStep + 1) / total).clamp(0.0, 1.0);

    return NovaCard(
      color: AppColors.deepInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande #${OrderStatusX.shortId(order.id)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              NovaStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Passée le ${OrderStatusX.formatDate(order.createdAt)}',
            style: const TextStyle(color: AppColors.lime, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.slow,
              curve: AppMotion.standard,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cancelled
                ? 'Commande annulée'
                : currentStep >= total - 1
                    ? 'Livraison terminée'
                    : 'Étape ${currentStep + 1} sur $total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Une étape animée de la frise de livraison.
class _TrackerStep extends StatelessWidget {
  const _TrackerStep({
    required this.step,
    required this.index,
    required this.done,
    required this.active,
    required this.isLast,
  });

  final OrderStep step;
  final int index;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- node + connector -----
          Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1),
                duration: AppMotion.normal,
                curve: AppMotion.emphasized,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: done ? AppColors.lime : context.colors.surface,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(
                            color: context.colors.textPrimary, width: 2.5)
                        : Border.all(color: context.colors.border, width: 1.2),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.lime.withValues(alpha: .5),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    done && !active ? Icons.check_rounded : step.icon,
                    color: done ? AppColors.ink : AppColors.muted,
                    size: 20,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.normal,
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: done ? AppColors.lime : context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // ----- step card -----
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: NovaCard(
                elevated: active,
                color: context.colors.surface,
                border: active
                    ? Border.all(color: AppColors.lime, width: 1.6)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: done
                                  ? context.colors.textPrimary
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                        if (active)
                          const NovaBadge(
                            label: 'En cours',
                            tone: NovaBadgeTone.primary,
                            dense: true,
                          )
                        else if (done)
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 18),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).fadeSlideIn(delay: AppMotion.stagger * index);
  }
}
