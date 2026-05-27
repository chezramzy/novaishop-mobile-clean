import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';

/// Liste des favoris de l'utilisateur, résolus en fiches produit.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Charge les favoris puis résout chaque entrée en [Listing].
  Future<List<Listing>> _load() async {
    final wishlist = context.read<WishlistRepository>();
    final catalog = context.read<CatalogRepository>();

    final items = await wishlist.getWishlist();
    if (items.isEmpty) return const [];

    // Résolution par lots : récupère le catalogue une seule fois.
    final byId = <String, Listing>{};
    final bySlug = <String, Listing>{};
    final collection = await catalog.getListings(pageSize: 100);
    for (final listing in collection.items) {
      byId[listing.id] = listing;
      bySlug[listing.slug] = listing;
    }

    final resolved = <Listing>[];
    for (final item in items) {
      final found = byId[item.listingId] ?? bySlug[item.listingId];
      if (found != null) {
        resolved.add(found);
        continue;
      }
      // Repli : tente une résolution directe par slug.
      try {
        resolved.add(await catalog.getListing(item.listingId));
      } catch (_) {
        // Produit indisponible — on l'ignore silencieusement.
      }
    }
    return resolved;
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _remove(Listing listing) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<WishlistRepository>().removeFromWishlist(listing.id);
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('« ${listing.title} » retiré des favoris.'),
          ),
        );
      _reload();
    } catch (error) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString()),
          ),
        );
    }
  }

  void _addToCart(Listing listing) {
    context.read<CartController>().add(listing);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('« ${listing.title} » ajouté au panier.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthController>().isAuthenticated;

    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Mes favoris'),
          ),
          Expanded(
            child: !isAuthenticated
                ? NovaEmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Connectez-vous',
                    message:
                        'Connectez-vous pour retrouver et gérer vos favoris.',
                    actionLabel: 'Se connecter',
                    onAction: () =>
                        Navigator.of(context).pushNamed(RouteNames.signIn),
                  )
                : _WishlistBody(
                    future: _future,
                    onReload: _reload,
                    onRemove: _remove,
                    onAddToCart: _addToCart,
                  ),
          ),
        ],
      ),
    );
  }
}

class _WishlistBody extends StatelessWidget {
  const _WishlistBody({
    required this.future,
    required this.onReload,
    required this.onRemove,
    required this.onAddToCart,
  });

  final Future<List<Listing>> future;
  final VoidCallback onReload;
  final ValueChanged<Listing> onRemove;
  final ValueChanged<Listing> onAddToCart;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Listing>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SkeletonGrid(itemCount: 6);
        }
        if (snapshot.hasError) {
          return NovaErrorState(
            message: snapshot.error.toString(),
            onRetry: onReload,
          );
        }
        final listings = snapshot.requireData;
        if (listings.isEmpty) {
          return NovaEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Aucun favori',
            message:
                'Ajoutez des produits à vos favoris pour les retrouver ici.',
            actionLabel: 'Découvrir le catalogue',
            onAction: () => Navigator.of(context).pushNamed(RouteNames.catalog),
          );
        }

        return RefreshIndicator(
          color: context.colors.textPrimary,
          onRefresh: () async => onReload(),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            itemCount: listings.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 18,
              childAspectRatio: .62,
            ),
            itemBuilder: (context, index) {
              final listing = listings[index];
              return StaggeredEntrance.item(
                index,
                ProductCard(
                  listing: listing,
                  isFavorite: true,
                  onTap: () => Navigator.of(context).pushNamed(
                    RouteNames.productDetail,
                    arguments: listing.slug,
                  ),
                  onFavorite: () => onRemove(listing),
                  onAdd: () => onAddToCart(listing),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
