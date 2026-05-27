import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';
import '../../design/design_system.dart';
import 'order_status.dart';

/// Liste des commandes du client, segmentée par statut.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _future;
  OrderTab _tab = OrderTab.enCours;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() async {
    final collection = await context.read<OrderRepository>().getOrders();
    return collection.items;
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<List<Order>>(
        future: _future,
        builder: (context, snapshot) {
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                const ScreenHeader(title: 'Mes commandes'),
                const SizedBox(height: 20),
                _OrderTabs(
                  current: _tab,
                  onChanged: (value) => setState(() => _tab = value),
                ),
              ],
            ),
          );

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                header,
                const SizedBox(height: 16),
                const Expanded(child: SkeletonList(itemCount: 5)),
              ],
            );
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                header,
                Expanded(
                  child: NovaErrorState(
                    message: snapshot.error.toString(),
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }

          final orders = OrderStatusX.sortByDate(snapshot.requireData);
          final filtered =
              orders.where((order) => _tab.matches(order.status)).toList();

          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      header,
                      const SizedBox(height: 40),
                      NovaEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: _tab.emptyTitle,
                        message: _tab.emptyMessage,
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 30),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: header,
                        );
                      }
                      final order = filtered[index - 1];
                      return StaggeredEntrance.item(
                        index - 1,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: _OrderCard(
                            order: order,
                            onTap: () => Navigator.of(context).pushNamed(
                              RouteNames.orderDetail,
                              arguments: order.id,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

/* ------------------------------- tabs --------------------------------- */

class _OrderTabs extends StatelessWidget {
  const _OrderTabs({required this.current, required this.onChanged});

  final OrderTab current;
  final ValueChanged<OrderTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          for (final tab in OrderTab.values)
            Expanded(
              child: _TabPill(
                label: tab.label,
                active: current == tab,
                onTap: () => onChanged(tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? AppColors.ink : AppColors.muted,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

/* ------------------------------- card --------------------------------- */

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstItem =
        order.items.isNotEmpty ? order.items.first.title : 'Commande';
    final extra = order.items.length - 1;

    return NovaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: context.colors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #${OrderStatusX.shortId(order.id)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      OrderStatusX.formatDate(order.createdAt),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              NovaStatusBadge(status: order.status, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.border),
          const SizedBox(height: 12),
          Text(
            extra > 0 ? '$firstItem  +$extra article(s)' : firstItem,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${order.itemCount} article(s)',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                formatPrice(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
