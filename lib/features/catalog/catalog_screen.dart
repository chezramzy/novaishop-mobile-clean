import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../design/design_system.dart';
import '../cart/cart_controller.dart';
import 'catalog_kit.dart';
import 'category_listings_screen.dart';

/// The catalogue hub: pick a marketplace universe (produits, services,
/// immobilier) and see a fresh selection from each.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  bool _loading = true;
  bool _failed = false;
  Map<CatalogType, List<Listing>> _byType = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repository = context.read<CatalogRepository>();
      final results = await Future.wait(
        CatalogType.values.map(
          (type) => repository.getListings(
            categoryType: type.apiValue,
            pageSize: 8,
          ),
        ),
      );
      if (!mounted) return;
      final map = <CatalogType, List<Listing>>{};
      for (var i = 0; i < CatalogType.values.length; i++) {
        map[CatalogType.values[i]] = results[i].items;
      }
      setState(() {
        _byType = map;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _openType(CatalogType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryListingsScreen(
          args: CategoryListingsArgs(
            categoryType: type.apiValue,
            title: type.label,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ScreenHeader(
              title: 'Découvrir',
              trailing: CircleIconButton(
                icon: Icons.search_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, RouteNames.search),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SkeletonList(
        itemCount: 5,
        itemHeight: 120,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 110),
      );
    }
    if (_failed) {
      return NovaErrorState(
        message: 'Impossible de charger le catalogue.',
        onRetry: _load,
      );
    }
    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _UniverseRow(onTap: _openType).fadeSlideIn(),
          const SizedBox(height: 8),
          for (var i = 0; i < CatalogType.values.length; i++)
            StaggeredEntrance.item(
              i + 1,
              _TypeSelection(
                type: CatalogType.values[i],
                listings: _byType[CatalogType.values[i]] ?? const [],
                onSeeAll: () => _openType(CatalogType.values[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _UniverseRow extends StatelessWidget {
  const _UniverseRow({required this.onTap});

  final ValueChanged<CatalogType> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in CatalogType.values) ...[
          Expanded(
            child: NovaCard(
              onTap: () => onTap(type),
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppColors.deepInk,
              child: Column(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: type.tintOf(NovaColors.light),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(type.icon, color: AppColors.deepInk, size: 21),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type.label,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (type != CatalogType.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TypeSelection extends StatelessWidget {
  const _TypeSelection({
    required this.type,
    required this.listings,
    required this.onSeeAll,
  });

  final CatalogType type;
  final List<Listing> listings;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: type.label, onAction: onSeeAll),
          const SizedBox(height: 4),
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return SizedBox(
                  width: 160,
                  child: ProductCard(
                    listing: listing,
                    onTap: () => Navigator.pushNamed(
                      context,
                      RouteNames.productDetail,
                      arguments: listing.slug,
                    ),
                    onAdd: () {
                      context.read<CartController>().add(listing);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${listing.title} ajouté au panier'),
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
