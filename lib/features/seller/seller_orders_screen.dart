import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/order.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'seller_order_detail_screen.dart';

/// Lists every order containing items sold by the seller, with a status
/// filter. Driven by `SellerRepository.getVendorOrders`.
class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({required this.vendorId, super.key});

  final String vendorId;

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  late Future<List<Order>> _future;
  String _filter = 'all';

  static const _filters = <(String, String)>[
    ('all', 'Toutes'),
    ('pending', 'En attente'),
    ('paid', 'Payées'),
    ('processing', 'En préparation'),
    ('shipped', 'Expédiées'),
    ('delivered', 'Livrées'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Order>> _load() async {
    final repository = SellerRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    final collection = await repository.getVendorOrders(
      widget.vendorId,
      pageSize: 50,
    );
    return collection.items;
  }

  void _reload() => setState(() => _future = _load());

  List<Order> _applyFilter(List<Order> orders) {
    if (_filter == 'all') return orders;
    return orders.where((order) => order.status == _filter).toList();
  }

  Future<void> _openDetail(Order order) async {
    final updated = await Navigator.of(context).push<bool>(
      AppPageRoute.sharedAxis(
        SellerOrderDetailScreen(
          args: SellerOrderDetailArgs(order: order, vendorId: widget.vendorId),
        ),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Mes commandes'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return NovaChip(
                  label: filter.$2,
                  selected: _filter == filter.$1,
                  onTap: () => setState(() => _filter = filter.$1),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: FutureBuilder<List<Order>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const NovaLoadingView(
                    label: 'Chargement des commandes…',
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return NovaErrorState(
                    message: error is RepositoryException
                        ? error.message
                        : 'Impossible de charger les commandes.',
                    onRetry: _reload,
                  );
                }
                final all = snapshot.requireData;
                final orders = _applyFilter(all);
                if (orders.isEmpty) {
                  return NovaEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title:
                        all.isEmpty ? 'Aucune commande' : 'Aucune commande ici',
                    message: all.isEmpty
                        ? 'Vos commandes apparaîtront ici dès votre '
                            'première vente.'
                        : 'Aucune commande ne correspond à ce filtre.',
                  );
                }
                return RefreshIndicator(
                  color: context.colors.textPrimary,
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) => StaggeredEntrance.item(
                      index,
                      _OrderCard(
                        order: orders[index],
                        onTap: () => _openDetail(orders[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    return NovaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: context.colors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commande #$shortId',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${order.itemCount} article(s)',
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
          Divider(height: AppSpacing.lg, color: context.colors.border),
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 16, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                formatPrice(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Text(
                'Détails',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}
