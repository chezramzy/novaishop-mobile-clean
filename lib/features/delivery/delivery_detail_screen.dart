import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/delivery.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'driver_format.dart';

/// Detail of a single delivery with the status workflow:
/// `assigned → accepted → picked_up → in_transit → delivered`.
class DeliveryDetailScreen extends StatefulWidget {
  const DeliveryDetailScreen({required this.deliveryId, super.key});

  final String deliveryId;

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  /// Ordered "happy path" of delivery statuses.
  static const _flow = [
    'assigned',
    'accepted',
    'picked_up',
    'in_transit',
    'delivered',
  ];

  late Future<Delivery> _future;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Delivery> _load() {
    return context.read<DriverRepository>().getDelivery(widget.deliveryId);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  String? _nextStatus(String current) {
    final index = _flow.indexOf(current);
    if (index < 0 || index >= _flow.length - 1) return null;
    return _flow[index + 1];
  }

  String _actionLabel(String nextStatus) {
    switch (nextStatus) {
      case 'accepted':
        return 'Accepter la livraison';
      case 'picked_up':
        return 'Confirmer le retrait';
      case 'in_transit':
        return 'Démarrer la livraison';
      case 'delivered':
        return 'Marquer comme livrée';
      default:
        return 'Mettre à jour';
    }
  }

  Future<void> _advance(Delivery delivery) async {
    final next = _nextStatus(delivery.status);
    if (next == null || _updating) return;
    setState(() => _updating = true);
    try {
      await context.read<DriverRepository>().updateDeliveryStatus(
            delivery.id,
            status: next,
          );
      if (!mounted) return;
      setState(() {
        _updating = false;
        _future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Statut mis à jour : ${DeliveryFormat.statusLabel(next)}.'),
        ),
      );
    } on RepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour impossible. Veuillez réessayer.'),
        ),
      );
    }
  }

  Future<void> _callCustomer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appel indisponible sur cet appareil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<Delivery>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ScreenHeader(title: 'Livraison'),
                ),
                Expanded(child: NovaLoadingView()),
              ],
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ScreenHeader(title: 'Livraison'),
                ),
                Expanded(
                  child: NovaErrorState(
                    message: error is RepositoryException
                        ? error.message
                        : 'Impossible de charger cette livraison.',
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }
          final delivery = snapshot.data!;
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: _DetailBody(
              delivery: delivery,
              flow: _flow,
              updating: _updating,
              nextStatus: _nextStatus(delivery.status),
              actionLabel: _actionLabel,
              onAdvance: () => _advance(delivery),
              onCallCustomer: () => _callCustomer(delivery.customerPhone),
            ),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.delivery,
    required this.flow,
    required this.updating,
    required this.nextStatus,
    required this.actionLabel,
    required this.onAdvance,
    required this.onCallCustomer,
  });

  final Delivery delivery;
  final List<String> flow;
  final bool updating;
  final String? nextStatus;
  final String Function(String) actionLabel;
  final VoidCallback onAdvance;
  final VoidCallback onCallCustomer;

  @override
  Widget build(BuildContext context) {
    final terminal = delivery.status == 'failed' ||
        delivery.status == 'cancelled' ||
        delivery.status == 'delivered';
    final itemCount =
        delivery.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        Row(
          children: [
            CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Livraison', style: AppTypography.title),
                  Text(
                    'Commande #${_shortId(delivery.orderId)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            NovaStatusBadge(status: delivery.status),
          ],
        ),
        const SizedBox(height: 20),
        _StatusStepper(currentStatus: delivery.status, flow: flow),
        const SizedBox(height: 16),
        _AddressCard(
          icon: Icons.store_mall_directory_rounded,
          tint: context.colors.butter,
          title: 'Point de retrait',
          address: delivery.pickupAddress,
          city: delivery.pickupCity,
        ),
        const SizedBox(height: 12),
        _AddressCard(
          icon: Icons.location_on_rounded,
          tint: context.colors.lavender,
          title: 'Adresse de livraison',
          address: delivery.deliveryAddress,
          city: delivery.deliveryCity,
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Client'),
        const SizedBox(height: 8),
        NovaCard(
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.customerName.isEmpty
                          ? 'Client'
                          : delivery.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if (delivery.customerPhone.isNotEmpty)
                      Text(
                        delivery.customerPhone,
                        style: AppTypography.caption,
                      ),
                  ],
                ),
              ),
              if (delivery.customerPhone.isNotEmpty)
                CircleIconButton(
                  icon: Icons.phone_rounded,
                  backgroundColor: AppColors.lime,
                  onPressed: onCallCustomer,
                  tooltip: 'Appeler le client',
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Colis'),
        const SizedBox(height: 8),
        NovaCard(
          child: Column(
            children: [
              if (delivery.items.isEmpty)
                Text(
                  'Aucun article détaillé pour cette commande.',
                  style: AppTypography.bodyMuted,
                )
              else
                for (var i = 0; i < delivery.items.length; i++) ...[
                  if (i > 0) Divider(height: 16, color: context.colors.border),
                  Row(
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${delivery.items[i].quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          delivery.items[i].title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        NovaCard(
          color: AppColors.deepInk,
          child: Column(
            children: [
              _MoneyRow(
                label: 'Articles',
                value: '$itemCount',
                dark: true,
              ),
              const SizedBox(height: 8),
              _MoneyRow(
                label: 'Frais de livraison',
                value: formatPrice(delivery.deliveryFee),
                dark: true,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFF3A413C)),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Votre gain',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(delivery.driverEarning),
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (delivery.trackingNumber != null ||
            delivery.estimatedDeliveryTime != null) ...[
          const SizedBox(height: 12),
          NovaCard(
            child: Column(
              children: [
                if (delivery.trackingNumber != null)
                  _InfoRow(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Numéro de suivi',
                    value: delivery.trackingNumber!,
                  ),
                if (delivery.trackingNumber != null &&
                    delivery.estimatedDeliveryTime != null)
                  const SizedBox(height: 10),
                if (delivery.estimatedDeliveryTime != null)
                  _InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Livraison estimée',
                    value: DeliveryFormat.dateTime(
                      delivery.estimatedDeliveryTime!,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (delivery.notes != null && delivery.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          NovaCard(
            color: AppColors.butter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sticky_note_2_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (terminal)
          NovaCard(
            color: delivery.status == 'delivered'
                ? AppColors.success.withValues(alpha: .12)
                : AppColors.blush,
            child: Row(
              children: [
                Icon(
                  delivery.status == 'delivered'
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: delivery.status == 'delivered'
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    delivery.status == 'delivered'
                        ? 'Livraison terminée. Merci pour votre course !'
                        : 'Cette livraison est ${DeliveryFormat.statusLabel(delivery.status).toLowerCase()}.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else if (nextStatus != null)
          NovaButton.primary(
            label: actionLabel(nextStatus!),
            icon: Icons.arrow_forward_rounded,
            busy: updating,
            onPressed: onAdvance,
          ),
      ]),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}

/// Animated vertical stepper showing the delivery workflow progress.
class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.currentStatus, required this.flow});

  final String currentStatus;
  final List<String> flow;

  @override
  Widget build(BuildContext context) {
    final terminalBad =
        currentStatus == 'failed' || currentStatus == 'cancelled';
    var currentIndex = flow.indexOf(currentStatus);
    if (currentIndex < 0) currentIndex = terminalBad ? -1 : 0;

    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_rounded, size: 18),
              const SizedBox(width: 6),
              Text('Progression', style: AppTypography.subtitle),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < flow.length; i++)
            _StepRow(
              label: DeliveryFormat.statusLabel(flow[i]),
              done: i < currentIndex,
              active: i == currentIndex,
              isLast: i == flow.length - 1,
              delay: AppMotion.stagger * i,
            ),
          if (terminalBad) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 8),
                Text(
                  'Livraison ${DeliveryFormat.statusLabel(currentStatus).toLowerCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
    required this.isLast,
    required this.delay,
  });

  final String label;
  final bool done;
  final bool active;
  final bool isLast;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final reached = done || active;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: reached ? AppColors.lime : context.colors.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? context.colors.textPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Icon(
                  done ? Icons.check_rounded : Icons.circle,
                  size: done ? 15 : 8,
                  color: reached ? AppColors.deepInk : AppColors.muted,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.4,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? AppColors.lime : context.colors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14, top: 3),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: reached ? context.colors.textPrimary : AppColors.muted,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ).fadeSlideIn(delay: delay);
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.address,
    required this.city,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String address;
  final String city;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: context.colors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address.isEmpty ? 'Adresse non précisée' : address,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (city.isNotEmpty) Text(city, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.dark = false,
  });

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? const Color(0xFFB9C0B7) : AppColors.muted;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: dark ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.textPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
