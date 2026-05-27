import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../cart/cart_controller.dart';
import '../product/product_detail_screen.dart';

/// Public catalogue tab. Partner identities remain internal: customers only
/// browse products published under the NovaShop brand.
class ShopTab extends StatefulWidget {
  const ShopTab({super.key});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Listing>> _load() async {
    final collection = await context.read<CatalogRepository>().getListings(
          pageSize: 40,
          status: 'published',
        );
    return collection.items;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _openProduct(Listing listing) {
    Navigator.of(context).pushNamed(
      RouteNames.productDetail,
      arguments: ProductDetailArgs(slug: listing.slug),
    );
  }

  void _quickAdd(Listing listing) {
    if (listing.variants.isNotEmpty) {
      _openProduct(listing);
      return;
    }
    context.read<CartController>().add(listing);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${listing.title} ajoute au panier.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<List<Listing>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ScreenHeader(title: 'Catalogue', showBack: false),
                ),
                SizedBox(height: 8),
                Expanded(child: SkeletonList(itemCount: 6)),
              ],
            );
          }
          if (snapshot.hasError) {
            return NovaErrorState(
              message: snapshot.error is RepositoryException
                  ? (snapshot.error as RepositoryException).message
                  : 'Impossible de charger le catalogue.',
              onRetry: _reload,
            );
          }

          final products = snapshot.requireData;
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: products.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: const [
                      ScreenHeader(title: 'Catalogue', showBack: false),
                      SizedBox(height: 60),
                      NovaEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aucun produit',
                        message:
                            'Revenez bientot : de nouveaux produits arrivent.',
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                    itemCount: products.length + 1,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 18,
                      childAspectRatio: .68,
                    ),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _CatalogIntroCard();
                      }
                      final listing = products[index - 1];
                      return ProductCard(
                        listing: listing,
                        onTap: () => _openProduct(listing),
                        onAdd: () => _quickAdd(listing),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _CatalogIntroCard extends StatelessWidget {
  const _CatalogIntroCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.lime),
            Spacer(),
            Text(
              'Catalogue NovaShop',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Produits, variantes et offres disponibles au meme endroit.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
