import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../cart/cart_controller.dart';
import 'catalog_kit.dart';

/// A dedicated flash-sales page with live countdowns and discount badges.
class FlashSalesScreen extends StatefulWidget {
  const FlashSalesScreen({super.key});

  @override
  State<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends State<FlashSalesScreen> {
  bool _loading = true;
  RepositoryException? _error;
  List<Listing> _listings = const [];

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
      final collection =
          await context.read<CatalogRepository>().getFlashSales();
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
        _error = RepositoryException('Impossible de charger les ventes flash.');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: ScreenHeader(title: 'Ventes flash'),
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
        itemHeight: 110,
        padding: EdgeInsets.fromLTRB(20, 8, 20, 110),
      );
    }
    if (_error != null) {
      return NovaErrorState(message: _error!.message, onRetry: _load);
    }
    if (_listings.isEmpty) {
      return NovaEmptyState(
        icon: Icons.flash_on_outlined,
        title: 'Aucune vente flash',
        message: 'Revenez bientôt pour profiter de nos offres limitées.',
        actionLabel: 'Actualiser',
        onAction: _load,
      );
    }
    return RefreshIndicator(
      color: context.colors.textPrimary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
        children: [
          const _FlashBanner().fadeSlideIn(),
          const SizedBox(height: 16),
          for (var i = 0; i < _listings.length; i++)
            StaggeredEntrance.item(
              i,
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FlashRow(
                  listing: _listings[i],
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.productDetail,
                    arguments: _listings[i].slug,
                  ),
                  onAdd: () {
                    context.read<CartController>().add(_listings[i]);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${_listings[i].title} ajouté au panier'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlashBanner extends StatelessWidget {
  const _FlashBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.flash_on_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres à durée limitée',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Les prix remontent dès la fin du compte à rebours.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashRow extends StatelessWidget {
  const _FlashRow({
    required this.listing,
    required this.onTap,
    required this.onAdd,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final discount = listing.discountPercent;
    return NovaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: NovaImage(
                  url: listing.displayImage,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(color: AppColors.butter),
                  error: const ColoredBox(
                    color: AppColors.butter,
                    child: Icon(Icons.image_outlined, size: 20),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      formatPrice(listing.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (listing.originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatPrice(listing.originalPrice!),
                        style: const TextStyle(
                          color: AppColors.muted,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CountdownChip(endAt: listing.flashSaleEndAt),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 36,
                      child: IconButton.filled(
                        padding: EdgeInsets.zero,
                        onPressed: onAdd,
                        icon: const Icon(Icons.add_rounded, size: 19),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.deepInk,
                          foregroundColor: AppColors.lime,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
