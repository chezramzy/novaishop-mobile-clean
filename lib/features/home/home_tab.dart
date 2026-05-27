import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../catalog/catalog_kit.dart';
import '../catalog/category_listings_screen.dart';
import '../categories/categories_screen.dart';

/// The buyer's enriched "Accueil" feed: greeting, search, category rail,
/// flash sales with live countdown, best-sellers, new arrivals, featured
/// sellers and a marketplace stats band.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _loading = true;
  bool _failed = false;
  _HomeData _data = const _HomeData();

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
    final repository = context.read<CatalogRepository>();
    try {
      // Core feeds — required.
      final categories = await repository.getCategories();
      final bestSellers = await repository.getBestSellers();
      final newArrivals = await repository.getNewArrivals();

      // Optional feeds — degrade gracefully if any fails.
      List<Listing> flashSales = const [];
      List<FeaturedSeller> sellers = const [];
      CatalogStats? stats;
      try {
        flashSales = (await repository.getFlashSales()).items;
      } catch (_) {/* optional */}
      try {
        sellers = await repository.getFeaturedSellers();
      } catch (_) {/* optional */}
      try {
        stats = await repository.getStats();
      } catch (_) {/* optional */}

      if (!mounted) return;
      setState(() {
        _data = _HomeData(
          categories: categories.items,
          bestSellers: bestSellers.items,
          newArrivals: newArrivals.items,
          flashSales: flashSales,
          sellers: sellers,
          stats: stats,
        );
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

  void _openProduct(Listing listing) {
    Navigator.pushNamed(
      context,
      RouteNames.productDetail,
      arguments: listing.slug,
    );
  }

  void _addToCart(Listing listing) {
    context.read<CartController>().add(listing);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${listing.title} ajouté au panier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _HomeSkeleton();
    }
    if (_failed) {
      return NovaErrorState(
        message: 'Impossible de charger la page d\'accueil.',
        onRetry: _load,
      );
    }
    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const _HomeHeader().fadeSlideIn(),
          const SizedBox(height: 16),
          _SearchEntry(
            onTap: () => Navigator.pushNamed(context, RouteNames.search),
          ).fadeSlideIn(delay: AppMotion.stagger),
          const SizedBox(height: 20),
          _CategoryRail(
            categories: _data.categories,
            onSelect: _openCategory,
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ).fadeSlideIn(delay: AppMotion.stagger * 2),
          const SizedBox(height: 22),
          if (_data.flashSales.isNotEmpty) ...[
            _FlashSalesStrip(
              listings: _data.flashSales,
              onSeeAll: () =>
                  Navigator.pushNamed(context, RouteNames.flashSales),
              onTap: _openProduct,
            ).fadeSlideIn(delay: AppMotion.stagger * 3),
            const SizedBox(height: 22),
          ],
          if (_data.bestSellers.isNotEmpty) ...[
            SectionHeader(
              title: 'Meilleures ventes',
              onAction: () => Navigator.pushNamed(context, RouteNames.catalog),
            ),
            const SizedBox(height: 4),
            _ProductCarousel(
              listings: _data.bestSellers,
              onTap: _openProduct,
              onAdd: _addToCart,
            ),
            const SizedBox(height: 22),
          ],
          _UniverseShortcuts(onSelect: _openType)
              .fadeSlideIn(delay: AppMotion.stagger),
          const SizedBox(height: 22),
          if (_data.newArrivals.isNotEmpty) ...[
            SectionHeader(
              title: 'Nouveautés',
              onAction: () => Navigator.pushNamed(context, RouteNames.catalog),
            ),
            const SizedBox(height: 8),
            _NewArrivalsGrid(
              listings: _data.newArrivals,
              onTap: _openProduct,
              onAdd: _addToCart,
            ),
            const SizedBox(height: 22),
          ],
          if (_data.sellers.isNotEmpty) ...[
            const SectionHeader(title: 'Boutiques en vedette'),
            const SizedBox(height: 4),
            _FeaturedSellersRow(sellers: _data.sellers),
            const SizedBox(height: 22),
          ],
          if (_data.stats != null)
            _StatsBand(stats: _data.stats!)
                .fadeSlideIn(delay: AppMotion.stagger),
        ],
      ),
    );
  }

  void _openCategory(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryListingsScreen(
          args: CategoryListingsArgs(
            categoryId: category.id,
            categoryType: category.type,
            title: category.name,
          ),
        ),
      ),
    );
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
}

/* -------------------------------- header --------------------------------- */

class _HomeHeader extends StatefulWidget {
  const _HomeHeader();

  @override
  State<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<_HomeHeader> {
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final count =
          await context.read<NotificationRepository>().getUnreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {
      // Le badge reste silencieux si le compteur est indisponible.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, RouteNames.notifications);
    if (mounted) _loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartController>().count;
    final user = context.watch<AuthController>().user;
    final firstName = (user?.firstName ?? '').trim();
    final greeting = firstName.isEmpty ? 'Bonjour' : 'Bonjour, $firstName';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: context.colors.textPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Livraison à Paris',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                greeting,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: Icons.shopping_bag_outlined,
              onPressed: () => Navigator.pushNamed(context, RouteNames.cart),
            ),
            if (cartCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppColors.danger,
                  child: Text(
                    '$cartCount',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ).popIn(),
              ),
          ],
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: _openNotifications,
            ),
            if (_unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    _unread > 99 ? '99+' : '$_unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ).popIn(),
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: context.colors.border, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.muted),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Produits, services, biens immobiliers…',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
              Icon(
                Icons.tune_rounded,
                color: context.colors.textPrimary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- category rail ----------------------------- */

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.onSelect,
    required this.onSeeAll,
  });

  final List<Category> categories;
  final ValueChanged<Category> onSelect;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final visible = categories.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Catégories', onAction: onSeeAll),
        const SizedBox(height: 4),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final category = visible[index];
              return StaggeredEntrance.item(
                index,
                SizedBox(
                  width: 72,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onSelect(category),
                    child: Column(
                      children: [
                        Container(
                          height: 58,
                          width: 58,
                          decoration: BoxDecoration(
                            color: softTintFor(category.id, context.colors),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            categoryIcon(category.slug, category.type),
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- flash sales ------------------------------- */

class _FlashSalesStrip extends StatelessWidget {
  const _FlashSalesStrip({
    required this.listings,
    required this.onSeeAll,
    required this.onTap,
  });

  final List<Listing> listings;
  final VoidCallback onSeeAll;
  final ValueChanged<Listing> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                color: AppColors.lime,
                size: 20,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Ventes flash',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lime,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Voir tout',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _FlashCard(
                listing: listings[index],
                onTap: () => onTap(listings[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = listing.discountPercent;
    return SizedBox(
      width: 150,
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: NovaImage(
                            url: listing.displayImage,
                            fit: BoxFit.cover,
                            placeholder:
                                const ColoredBox(color: AppColors.butter),
                            error: const ColoredBox(
                              color: AppColors.butter,
                              child: Icon(Icons.image_outlined, size: 20),
                            ),
                          ),
                        ),
                      ),
                      if (discount != null)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: DiscountBadge(percent: discount),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      formatPrice(listing.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    if (listing.originalPrice != null) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          formatPrice(listing.originalPrice!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                CountdownChip(endAt: listing.flashSaleEndAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------- product carousels --------------------------- */

class _ProductCarousel extends StatelessWidget {
  const _ProductCarousel({
    required this.listings,
    required this.onTap,
    required this.onAdd,
  });

  final List<Listing> listings;
  final ValueChanged<Listing> onTap;
  final ValueChanged<Listing> onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 256,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final listing = listings[index];
          return StaggeredEntrance.item(
            index,
            SizedBox(
              width: 168,
              child: ProductCard(
                listing: listing,
                onTap: () => onTap(listing),
                onAdd: () => onAdd(listing),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewArrivalsGrid extends StatelessWidget {
  const _NewArrivalsGrid({
    required this.listings,
    required this.onTap,
    required this.onAdd,
  });

  final List<Listing> listings;
  final ValueChanged<Listing> onTap;
  final ValueChanged<Listing> onAdd;

  @override
  Widget build(BuildContext context) {
    final visible = listings.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: .66,
      ),
      itemBuilder: (context, index) {
        final listing = visible[index];
        return StaggeredEntrance.item(
          index,
          ProductCard(
            listing: listing,
            onTap: () => onTap(listing),
            onAdd: () => onAdd(listing),
          ),
        );
      },
    );
  }
}

/* --------------------------- universe shortcuts -------------------------- */

class _UniverseShortcuts extends StatelessWidget {
  const _UniverseShortcuts({required this.onSelect});

  final ValueChanged<CatalogType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Explorer la marketplace'),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final type in CatalogType.values) ...[
              Expanded(
                child: NovaCard(
                  onTap: () => onSelect(type),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 8,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: type.tintOf(context.colors),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          type.icon,
                          color: context.colors.textPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type.label,
                        style: const TextStyle(
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
        ),
      ],
    );
  }
}

/* ---------------------------- featured sellers --------------------------- */

class _FeaturedSellersRow extends StatelessWidget {
  const _FeaturedSellersRow({required this.sellers});

  final List<FeaturedSeller> sellers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sellers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final seller = sellers[index];
          return StaggeredEntrance.item(
            index,
            _SellerCard(seller: seller),
          );
        },
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.seller});

  final FeaturedSeller seller;

  @override
  Widget build(BuildContext context) {
    final shop = seller.shop;
    final initial =
        shop.name.trim().isNotEmpty ? shop.name.trim()[0].toUpperCase() : 'B';
    return SizedBox(
      width: 158,
      child: NovaCard(
        onTap: shop.slug.isEmpty
            ? null
            : () => Navigator.pushNamed(
                  context,
                  RouteNames.shopPage,
                  arguments: shop.slug,
                ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              shop.name.isEmpty ? 'Boutique' : shop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${seller.listingCount} annonce${seller.listingCount > 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------ stats band ------------------------------- */

class _StatsBand extends StatelessWidget {
  const _StatsBand({required this.stats});

  final CatalogStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Text(
            'NovAiShop en chiffres',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatCell(
                value: stats.totalListings,
                label: 'Annonces',
                icon: Icons.inventory_2_outlined,
              ),
              _StatCell(
                value: stats.totalSellers,
                label: 'Partenaires',
                icon: Icons.verified_outlined,
              ),
              _StatCell(
                value: stats.totalOrders,
                label: 'Commandes',
                icon: Icons.receipt_long_outlined,
              ),
              _StatCell(
                value: stats.totalUsers,
                label: 'Membres',
                icon: Icons.groups_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
  });

  final int value;
  final String label;
  final IconData icon;

  String get _formatted {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k';
    }
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.lime, size: 20),
          const SizedBox(height: 6),
          Text(
            _formatted,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- skeleton -------------------------------- */

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NovaSkeleton(width: 120, height: 12),
                  SizedBox(height: 8),
                  NovaSkeleton(width: 160, height: 18),
                ],
              ),
            ),
            NovaSkeleton.circle(size: 44),
            SizedBox(width: 8),
            NovaSkeleton.circle(size: 44),
          ],
        ),
        const SizedBox(height: 18),
        const NovaSkeleton(height: 54, radius: AppSpacing.radiusMd),
        const SizedBox(height: 22),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => const Column(
              children: [
                NovaSkeleton(width: 58, height: 58, radius: 18),
                SizedBox(height: 8),
                NovaSkeleton(width: 50, height: 10),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const NovaSkeleton(height: 196, radius: 22),
        const SizedBox(height: 22),
        const SizedBox(
          height: 520,
          child: SkeletonGrid(
            itemCount: 4,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

/* ------------------------------ data model ------------------------------- */

class _HomeData {
  const _HomeData({
    this.categories = const [],
    this.bestSellers = const [],
    this.newArrivals = const [],
    this.flashSales = const [],
    this.sellers = const [],
    this.stats,
  });

  final List<Category> categories;
  final List<Listing> bestSellers;
  final List<Listing> newArrivals;
  final List<Listing> flashSales;
  final List<FeaturedSeller> sellers;
  final CatalogStats? stats;
}
