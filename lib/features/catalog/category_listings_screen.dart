import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../cart/cart_controller.dart';
import 'catalog_kit.dart';

/// Arguments for the category listings screen.
class CategoryListingsArgs {
  const CategoryListingsArgs({
    this.categoryId,
    this.categoryType,
    required this.title,
  });

  /// Optional category id to filter by.
  final String? categoryId;

  /// Optional category type (product/service/property).
  final String? categoryType;

  /// Title shown in the header.
  final String title;
}

/// Lists listings filtered by category, with an inline sort control.
class CategoryListingsScreen extends StatefulWidget {
  const CategoryListingsScreen({required this.args, super.key});

  final CategoryListingsArgs args;

  @override
  State<CategoryListingsScreen> createState() => _CategoryListingsScreenState();
}

class _CategoryListingsScreenState extends State<CategoryListingsScreen> {
  bool _loading = true;
  RepositoryException? _error;
  List<Listing> _listings = const [];
  CatalogSort _sort = CatalogSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final collection = await context.read<CatalogRepository>().getListings(
            categoryId: widget.args.categoryId,
            categoryType: widget.args.categoryType,
            sort: _sort.apiValue,
            pageSize: 40,
          );
      if (!mounted) return;
      setState(() {
        _listings = collection.items;
        _loading = false;
      });
    } on RepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = RepositoryException(
          'Impossible de charger cette catégorie.',
        );
        _loading = false;
      });
    }
  }

  void _changeSort(CatalogSort sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ScreenHeader(title: widget.args.title),
          ),
          _SortBar(sort: _sort, onChanged: _changeSort),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SkeletonGrid(
        itemCount: 6,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 110),
      );
    }
    if (_error != null) {
      return NovaErrorState(message: _error!.message, onRetry: _load);
    }
    if (_listings.isEmpty) {
      return NovaEmptyState(
        icon: Icons.category_outlined,
        title: 'Catégorie vide',
        message: 'Aucune annonce disponible ici pour le moment.',
        actionLabel: 'Actualiser',
        onAction: _load,
      );
    }
    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        itemCount: _listings.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
          childAspectRatio: .66,
        ),
        itemBuilder: (context, index) {
          final listing = _listings[index];
          return StaggeredEntrance.item(
            index,
            ProductCard(
              listing: listing,
              onTap: () => Navigator.pushNamed(
                context,
                RouteNames.productDetail,
                arguments: listing.slug,
              ),
              onAdd: () {
                context.read<CartController>().add(listing);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${listing.title} ajouté au panier')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.sort, required this.onChanged});

  final CatalogSort sort;
  final ValueChanged<CatalogSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: CatalogSort.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = CatalogSort.values[index];
          return Center(
            child: NovaChip(
              label: option.label,
              icon: option.icon,
              selected: option == sort,
              onTap: () => onChanged(option),
            ),
          );
        },
      ),
    );
  }
}
