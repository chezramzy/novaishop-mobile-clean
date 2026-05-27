import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/models/product_variant.dart';
import '../../data/models/review.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/review_repository.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../reviews/review_widgets.dart';
import '../reviews/reviews_screen.dart';
import '../reviews/write_review_screen.dart';

/// Arguments passed to the product detail route.
class ProductDetailArgs {
  const ProductDetailArgs({required this.slug});

  final String slug;
}

/// Bundles the listing with its related data fetched in one go.
class _ProductBundle {
  const _ProductBundle({
    required this.listing,
    required this.reviews,
    required this.similar,
  });

  final Listing listing;
  final List<Review> reviews;
  final List<Listing> similar;

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.map((r) => r.rating).reduce((a, b) => a + b);
    return sum / reviews.length;
  }
}

/// The product detail screen: gallery, pricing, variant selectors,
/// quantity, add-to-cart / buy-now, description, reviews, seller card
/// and similar products.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<_ProductBundle> _future;

  final Map<String, String> _selectedVariants = {};
  int _quantity = 1;
  int _galleryIndex = 0;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ProductBundle> _load() async {
    final catalog = context.read<CatalogRepository>();
    final accessToken = context.read<AuthController>().accessToken;
    final listing = await catalog.getListing(widget.slug);

    List<Review> reviews = const [];
    try {
      reviews = await ReviewRepository(accessToken: accessToken)
          .getListingReviews(listing.id);
    } catch (_) {
      reviews = const [];
    }

    List<Listing> similar = const [];
    try {
      final collection = await catalog.getListings(
        categoryType: listing.categoryType,
        pageSize: 12,
      );
      similar = collection.items
          .where((item) => item.id != listing.id)
          .take(6)
          .toList();
    } catch (_) {
      similar = const [];
    }

    return _ProductBundle(
      listing: listing,
      reviews: reviews,
      similar: similar,
    );
  }

  void _reload() {
    setState(() {
      _future = _load();
      _selectedVariants.clear();
      _quantity = 1;
      _galleryIndex = 0;
      _descriptionExpanded = false;
    });
  }

  /// Extracts variant option groups from `listing.attributes`.
  Map<String, List<String>> _variantGroups(Listing listing) {
    if (listing.variants.isNotEmpty) {
      final groups = <String, Set<String>>{};
      for (final variant in listing.variants) {
        variant.options.forEach((key, value) {
          if (value.trim().isEmpty) return;
          groups.putIfAbsent(key, () => <String>{}).add(value);
        });
      }
      return groups.map((key, value) => MapEntry(key, value.toList()));
    }

    final groups = <String, List<String>>{};
    listing.attributes.forEach((key, value) {
      if (_isLaptopAttribute(key)) return;
      if (value is List) {
        final options =
            value.map((v) => v.toString()).where((v) => v.isNotEmpty).toList();
        if (options.isNotEmpty) groups[key] = options;
      }
    });
    return groups;
  }

  void _addToCart(Listing listing) {
    final variantGroups = _variantGroups(listing);
    if (!_hasRequiredVariants(variantGroups)) return;
    final variant = _selectedVariantFor(listing);
    final cart = context.read<CartController>();
    for (var i = 0; i < _quantity; i++) {
      cart.add(
        listing,
        variant: variant,
        selectedOptions: Map<String, String>.from(_selectedVariants),
      );
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            _quantity == 1
                ? '${listing.title} ajouté au panier.'
                : '$_quantity × ${listing.title} ajoutés au panier.',
          ),
        ),
      );
  }

  void _buyNow(Listing listing) {
    final variantGroups = _variantGroups(listing);
    if (!_hasRequiredVariants(variantGroups)) return;
    final variant = _selectedVariantFor(listing);
    final cart = context.read<CartController>();
    for (var i = 0; i < _quantity; i++) {
      cart.add(
        listing,
        variant: variant,
        selectedOptions: Map<String, String>.from(_selectedVariants),
      );
    }
    Navigator.of(context).pushNamed(RouteNames.cart);
  }

  bool _hasRequiredVariants(Map<String, List<String>> variantGroups) {
    final missing = variantGroups.keys
        .where((key) => _selectedVariants[key]?.isNotEmpty != true)
        .toList();
    if (missing.isEmpty) return true;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Choisissez ${_attributeLabel(missing.first)}.'),
        ),
      );
    return false;
  }

  ProductVariant? _selectedVariantFor(Listing listing) {
    if (listing.variants.isEmpty) return null;
    for (final variant in listing.variants) {
      final matches = variant.options.entries.every(
        (entry) => _selectedVariants[entry.key] == entry.value,
      );
      if (matches) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<_ProductBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _LoadingProduct();
          }
          if (snapshot.hasError) {
            return Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 20,
                  child: CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                NovaErrorState(
                  message: snapshot.error is RepositoryException
                      ? (snapshot.error as RepositoryException).message
                      : 'Produit introuvable pour le moment.',
                  onRetry: _reload,
                ),
              ],
            );
          }

          final bundle = snapshot.requireData;
          return _ProductBody(
            bundle: bundle,
            variantGroups: _variantGroups(bundle.listing),
            selectedVariants: _selectedVariants,
            onSelectVariant: (group, value) =>
                setState(() => _selectedVariants[group] = value),
            quantity: _quantity,
            onQuantityChanged: (q) => setState(() => _quantity = q),
            galleryIndex: _galleryIndex,
            onGalleryChanged: (i) => setState(() => _galleryIndex = i),
            descriptionExpanded: _descriptionExpanded,
            onToggleDescription: () => setState(
              () => _descriptionExpanded = !_descriptionExpanded,
            ),
            onAddToCart: () => _addToCart(bundle.listing),
            onBuyNow: () => _buyNow(bundle.listing),
            onRefresh: () async => _reload(),
          );
        },
      ),
    );
  }
}

class _LoadingProduct extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: const [
        NovaSkeleton(height: 44, width: 44, radius: 999),
        SizedBox(height: 18),
        NovaSkeleton(height: 280, radius: AppSpacing.radiusXl),
        SizedBox(height: 18),
        NovaSkeleton(height: 22, width: 200),
        SizedBox(height: 10),
        NovaSkeleton(height: 18, width: 120),
        SizedBox(height: 20),
        NovaSkeleton(height: 14),
        SizedBox(height: 8),
        NovaSkeleton(height: 14, width: 240),
      ],
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.bundle,
    required this.variantGroups,
    required this.selectedVariants,
    required this.onSelectVariant,
    required this.quantity,
    required this.onQuantityChanged,
    required this.galleryIndex,
    required this.onGalleryChanged,
    required this.descriptionExpanded,
    required this.onToggleDescription,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onRefresh,
  });

  final _ProductBundle bundle;
  final Map<String, List<String>> variantGroups;
  final Map<String, String> selectedVariants;
  final void Function(String group, String value) onSelectVariant;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final int galleryIndex;
  final ValueChanged<int> onGalleryChanged;
  final bool descriptionExpanded;
  final VoidCallback onToggleDescription;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final listing = bundle.listing;
    final inStock = listing.isInStock;
    final isLaptop = _isLaptopListing(listing);

    return Stack(
      children: [
        RefreshIndicator(
          color: context.colors.textPrimary,
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  const CircleIconButton(icon: Icons.favorite_border_rounded),
                ],
              ),
              const SizedBox(height: 16),
              _Gallery(
                listing: listing,
                index: galleryIndex,
                onChanged: onGalleryChanged,
              ).fadeSlideIn(),
              const SizedBox(height: 18),
              Text(
                listing.title,
                style: AppTypography.headline,
              ).fadeSlideIn(delay: AppMotion.fast),
              const SizedBox(height: 8),
              _PriceRow(listing: listing).fadeSlideIn(delay: AppMotion.fast),
              const SizedBox(height: 10),
              _StockRow(listing: listing),
              const SizedBox(height: 18),
              if (isLaptop) ...[
                _LaptopSpecsSection(listing: listing),
                const SizedBox(height: 20),
              ],
              if (variantGroups.isNotEmpty) ...[
                ...variantGroups.entries.map(
                  (entry) => _VariantSelector(
                    title: _attributeLabel(entry.key),
                    options: entry.value,
                    selected: selectedVariants[entry.key],
                    onSelect: (value) => onSelectVariant(entry.key, value),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _QuantityRow(
                quantity: quantity,
                maxQuantity: inStock ? listing.inventory : 1,
                enabled: inStock,
                onChanged: onQuantityChanged,
              ),
              const SizedBox(height: 20),
              _DescriptionSection(
                description: listing.description,
                expanded: descriptionExpanded,
                onToggle: onToggleDescription,
              ),
              const SizedBox(height: 22),
              _ReviewsSection(bundle: bundle),
              const SizedBox(height: 22),
              if (bundle.similar.isNotEmpty)
                _SimilarSection(
                  items: bundle.similar,
                ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: SafeArea(
            child: _BuyBar(
              listing: listing,
              enabled: inStock,
              onAddToCart: onAddToCart,
              onBuyNow: onBuyNow,
            ),
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- PC details ------------------------------- */

class _LaptopSpecsSection extends StatelessWidget {
  const _LaptopSpecsSection({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final specs = _laptopSpecs(listing.attributes);
    if (specs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(
                Icons.laptop_mac_rounded,
                color: AppColors.ink,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Caractéristiques PC',
                style: AppTypography.title,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 3 : 2;
            const spacing = 10.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final spec in specs)
                  SizedBox(
                    width: itemWidth,
                    child: _LaptopSpecTile(spec: spec),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LaptopSpecTile extends StatelessWidget {
  const _LaptopSpecTile({required this.spec});

  final _LaptopSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(spec.icon, size: 20, color: context.colors.textPrimary),
          const SizedBox(height: 10),
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- gallery -------------------------------- */

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.listing,
    required this.index,
    required this.onChanged,
  });

  final Listing listing;
  final int index;
  final ValueChanged<int> onChanged;

  /// The gallery sources — the primary image plus tinted fallbacks so the
  /// thumbnails feel like a real gallery.
  List<String> get _images {
    return [
      listing.displayImage,
      listing.displayImage,
      listing.displayImage,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final discount = listing.discountPercent;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: AspectRatio(
            aspectRatio: .92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.normal,
                  child: NovaImage(
                    key: ValueKey(index),
                    url: images[index],
                    fit: BoxFit.cover,
                    placeholder: const ColoredBox(color: AppColors.butter),
                    error: const ColoredBox(
                      color: AppColors.butter,
                      child: Icon(Icons.image_outlined, size: 42),
                    ),
                  ),
                ),
                if (discount != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: NovaBadge(
                      label: '-$discount %',
                      tone: NovaBadgeTone.danger,
                      icon: Icons.local_fire_department_rounded,
                    ).popIn(),
                  ),
                if (listing.isFlashSale)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: const NovaBadge(
                      label: 'Vente flash',
                      tone: NovaBadgeTone.primary,
                      icon: Icons.bolt_rounded,
                    ).popIn(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(images.length, (i) {
            final selected = i == index;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: selected
                          ? context.colors.textPrimary
                          : context.colors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd - 2),
                    child: NovaImage(
                      url: images[i],
                      fit: BoxFit.cover,
                      placeholder: const ColoredBox(color: AppColors.butter),
                      error: const ColoredBox(
                        color: AppColors.butter,
                        child: Icon(Icons.image_outlined, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/* -------------------------------- price --------------------------------- */

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatPrice(listing.price),
          style: AppTypography.display.copyWith(fontSize: 26),
        ),
        if (listing.originalPrice != null &&
            listing.originalPrice! > listing.price) ...[
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              formatPrice(listing.originalPrice!),
              style: const TextStyle(
                color: AppColors.muted,
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final inStock = listing.isInStock;
    final low = inStock && listing.inventory <= 5;
    return Row(
      children: [
        NovaBadge(
          label: inStock
              ? (low ? 'Plus que ${listing.inventory} en stock' : 'En stock')
              : 'Rupture de stock',
          tone: inStock
              ? (low ? NovaBadgeTone.warning : NovaBadgeTone.success)
              : NovaBadgeTone.danger,
          icon: inStock
              ? Icons.check_circle_outline_rounded
              : Icons.remove_shopping_cart_outlined,
        ),
      ],
    );
  }
}

/* ----------------------------- variants --------------------------------- */

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.subtitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              return NovaChip(
                label: _optionLabel(option),
                selected: selected == option,
                onTap: () => onSelect(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  const _QuantityRow({
    required this.quantity,
    required this.maxQuantity,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Quantité', style: AppTypography.subtitle),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                enabled: enabled && quantity > 1,
                onTap: () => onChanged(quantity - 1),
              ),
              SizedBox(
                width: 38,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                enabled: enabled && quantity < maxQuantity,
                onTap: () => onChanged(quantity + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? context.colors.textPrimary : context.colors.border,
          ),
        ),
      ),
    );
  }
}

/* ---------------------------- description ------------------------------- */

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final text = description.trim().isEmpty
        ? 'Aucune description disponible pour ce produit.'
        : description.trim();
    final isLong = text.length > 140;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: AppTypography.title),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: Text(
            text,
            maxLines: expanded || !isLong ? null : 3,
            overflow: expanded || !isLong
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ),
        if (isLong)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onToggle,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: context.colors.textPrimary,
              ),
              child: Text(
                expanded ? 'Voir moins' : 'Voir plus',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
      ],
    );
  }
}

/* ------------------------------ reviews --------------------------------- */

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.bundle});

  final _ProductBundle bundle;

  @override
  Widget build(BuildContext context) {
    final reviews = bundle.reviews;
    final recent = reviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Avis clients',
          actionLabel: reviews.isEmpty ? '' : 'Voir tous les avis',
          onAction: () => Navigator.of(context).pushNamed(
            RouteNames.reviews,
            arguments: ReviewsArgs(
              targetId: bundle.listing.id,
              targetName: bundle.listing.title,
            ),
          ),
        ),
        const SizedBox(height: 4),
        NovaCard(
          child: RatingSummary(
            average: bundle.averageRating,
            count: reviews.length,
          ),
        ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(recent.length, (index) {
            final review = recent[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewTile(
                authorName: review.customerName,
                rating: review.rating,
                comment: review.comment,
                createdAt: review.createdAt,
              ),
            );
          }),
        ],
        const SizedBox(height: 4),
        NovaButton.secondary(
          label: 'Donner mon avis',
          icon: Icons.edit_outlined,
          onPressed: () => _writeReview(context),
        ),
      ],
    );
  }

  Future<void> _writeReview(BuildContext context) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    if (!auth.isAuthenticated) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Connectez-vous pour publier un avis.'),
          ),
        );
      return;
    }
    final published = await openWriteReviewSheet(
      context,
      targetId: bundle.listing.id,
      targetName: bundle.listing.title,
    );
    if (published) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Merci ! Votre avis a été publié.'),
          ),
        );
    }
  }
}

/* ----------------------------- similar ---------------------------------- */

class _SimilarSection extends StatelessWidget {
  const _SimilarSection({required this.items});

  final List<Listing> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Produits similaires', style: AppTypography.title),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final listing = items[index];
              return StaggeredEntrance.item(
                index,
                SizedBox(
                  width: 150,
                  child: ProductCard(
                    listing: listing,
                    onTap: () => Navigator.of(context).pushNamed(
                      RouteNames.productDetail,
                      arguments: ProductDetailArgs(slug: listing.slug),
                    ),
                    onAdd: () {
                      context.read<CartController>().add(listing);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              '${listing.title} ajouté au panier.',
                            ),
                          ),
                        );
                    },
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

/* ------------------------------ buy bar --------------------------------- */

class _BuyBar extends StatelessWidget {
  const _BuyBar({
    required this.listing,
    required this.enabled,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final Listing listing;
  final bool enabled;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.shopping_bag_outlined,
          backgroundColor: AppColors.deepInk,
          foregroundColor: AppColors.lime,
          size: 56,
          tooltip: 'Ajouter au panier',
          onPressed: enabled ? onAddToCart : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NovaButton.primary(
            label: enabled ? 'Acheter maintenant' : 'Indisponible',
            icon: enabled ? Icons.flash_on_rounded : null,
            onPressed: enabled ? onBuyNow : null,
          ),
        ),
      ],
    ).fadeSlideIn(delay: AppMotion.normal);
  }
}

/* ------------------------------ helpers --------------------------------- */

/// Maps a raw attribute key to a French label.
String _attributeLabel(String key) {
  switch (key.toLowerCase()) {
    case 'color':
    case 'couleur':
      return 'Couleur';
    case 'size':
    case 'taille':
      return 'Taille';
    case 'material':
    case 'matiere':
    case 'matière':
      return 'Matière';
    case 'brand':
    case 'marque':
      return 'Marque';
    case 'condition':
    case 'etat':
    case 'état':
      return 'État';
    default:
      if (key.isEmpty) return key;
      return key[0].toUpperCase() + key.substring(1);
  }
}

/// Maps a raw attribute value to a French label where known.
String _optionLabel(String value) {
  switch (value.toLowerCase()) {
    case 'yellow':
      return 'Jaune';
    case 'white':
      return 'Blanc';
    case 'black':
      return 'Noir';
    case 'blue':
      return 'Bleu';
    case 'red':
      return 'Rouge';
    case 'green':
      return 'Vert';
    case 'purple':
      return 'Violet';
    case 'pink':
      return 'Rose';
    case 'grey':
    case 'gray':
      return 'Gris';
    case 'beige':
      return 'Beige';
    case 'brown':
      return 'Marron';
    default:
      return value;
  }
}

bool _isLaptopListing(Listing listing) {
  final attributes = listing.attributes;
  final template = '${attributes['productTemplate'] ?? ''}'.toLowerCase();
  final kind = '${attributes['productKind'] ?? ''}'.toLowerCase();
  final category = listing.categoryId.toLowerCase();
  return template == 'laptop' ||
      kind == 'laptop' ||
      category.contains('laptop') ||
      category.contains('ordinateur');
}

bool _isLaptopAttribute(String key) {
  switch (key) {
    case 'productTemplate':
    case 'productKind':
    case 'brand':
    case 'model':
    case 'processor':
    case 'ramGb':
    case 'storage':
    case 'gpu':
    case 'screenSize':
    case 'resolution':
    case 'operatingSystem':
    case 'condition':
    case 'batteryHealth':
    case 'warranty':
    case 'ports':
      return true;
    default:
      return false;
  }
}

List<_LaptopSpec> _laptopSpecs(Map<String, dynamic> attributes) {
  final specs = <_LaptopSpec>[];

  void add(String key, String label, IconData icon, {String suffix = ''}) {
    final value = _attrText(attributes[key], suffix: suffix);
    if (value.isEmpty) return;
    specs.add(_LaptopSpec(label: label, value: value, icon: icon));
  }

  final brand = _attrText(attributes['brand']);
  final model = _attrText(attributes['model']);
  final identity = [brand, model].where((value) => value.isNotEmpty).join(' ');
  if (identity.isNotEmpty) {
    specs.add(
      _LaptopSpec(
        label: 'Marque / modèle',
        value: identity,
        icon: Icons.badge_outlined,
      ),
    );
  }

  add('processor', 'Processeur', Icons.memory_rounded);
  add('ramGb', 'Mémoire RAM', Icons.developer_board_outlined, suffix: ' Go');
  add('storage', 'Stockage', Icons.storage_outlined);
  add('gpu', 'Carte graphique', Icons.videogame_asset_outlined);
  add('operatingSystem', 'Système', Icons.laptop_windows_outlined);
  add('screenSize', 'Écran', Icons.monitor_outlined);
  add('resolution', 'Résolution', Icons.aspect_ratio_outlined);
  add('condition', 'État', Icons.verified_outlined);
  add('batteryHealth', 'Batterie', Icons.battery_charging_full_outlined);
  add('ports', 'Connectique', Icons.settings_input_hdmi_outlined);
  add('warranty', 'Garantie', Icons.workspace_premium_outlined);

  return specs;
}

String _attrText(dynamic value, {String suffix = ''}) {
  if (value == null) return '';
  final text = '$value'.trim();
  if (text.isEmpty) return '';
  if (suffix.isNotEmpty &&
      !text.toLowerCase().endsWith(suffix.trim().toLowerCase())) {
    return '$text$suffix';
  }
  return text;
}

class _LaptopSpec {
  const _LaptopSpec({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}
