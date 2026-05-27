import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/delivery.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'delivery_widgets.dart';

/// Status filters available in the deliveries tab. `null` means "all".
class _DeliveryFilter {
  const _DeliveryFilter(this.label, this.status);

  final String label;
  final String? status;
}

const _filters = [
  _DeliveryFilter('Toutes', null),
  _DeliveryFilter('Assignées', 'assigned'),
  _DeliveryFilter('Acceptées', 'accepted'),
  _DeliveryFilter('Récupérées', 'picked_up'),
  _DeliveryFilter('En route', 'in_transit'),
  _DeliveryFilter('Livrées', 'delivered'),
];

/// The driver's "Livraisons" tab: the list of assigned deliveries with
/// status filter chips.
class DriverDeliveriesTab extends StatefulWidget {
  const DriverDeliveriesTab({super.key});

  @override
  State<DriverDeliveriesTab> createState() => _DriverDeliveriesTabState();
}

class _DriverDeliveriesTabState extends State<DriverDeliveriesTab> {
  int _selected = 0;
  late Future<List<Delivery>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Delivery>> _load() {
    return context
        .read<DriverRepository>()
        .getMyDeliveries(status: _filters[_selected].status);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _selectFilter(int index) {
    if (_selected == index) return;
    setState(() {
      _selected = index;
      _future = _load();
    });
  }

  Future<void> _openDetail(String deliveryId) async {
    await Navigator.of(context).pushNamed(
      RouteNames.deliveryDetail,
      arguments: deliveryId,
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Livraisons', showBack: false),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return NovaChip(
                  label: _filters[index].label,
                  selected: _selected == index,
                  onTap: () => _selectFilter(index),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Delivery>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const NovaLoadingView();
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return NovaErrorState(
                    message: error is RepositoryException
                        ? error.message
                        : 'Impossible de charger vos livraisons.',
                    onRetry: _reload,
                  );
                }
                final deliveries = snapshot.data ?? const [];
                if (deliveries.isEmpty) {
                  return RefreshIndicator(
                    color: context.colors.textPrimary,
                    onRefresh: () async => _reload(),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: NovaEmptyState(
                            icon: Icons.local_shipping_outlined,
                            title: 'Aucune livraison',
                            message: _selected == 0
                                ? 'Vous n\'avez aucune livraison pour le '
                                    'moment. Elles apparaîtront ici dès '
                                    'qu\'une commande vous sera assignée.'
                                : 'Aucune livraison avec ce statut.',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: context.colors.textPrimary,
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      return StaggeredEntrance.item(
                        index,
                        DeliveryListCard(
                          delivery: deliveries[index],
                          onTap: () => _openDetail(deliveries[index].id),
                        ),
                      );
                    },
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
