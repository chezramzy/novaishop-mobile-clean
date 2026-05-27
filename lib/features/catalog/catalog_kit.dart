import 'dart:async';

import 'package:flutter/material.dart';

import '../../design/design_system.dart';

/// Shared helpers, copy and small widgets for the WS1 discovery experience.

/// The three category types surfaced across the marketplace.
enum CatalogType { product, service, property }

extension CatalogTypeX on CatalogType {
  /// API value expected by `getListings(categoryType:)`.
  String get apiValue {
    switch (this) {
      case CatalogType.product:
        return 'product';
      case CatalogType.service:
        return 'service';
      case CatalogType.property:
        return 'property';
    }
  }

  /// French plural label.
  String get label {
    switch (this) {
      case CatalogType.product:
        return 'Produits';
      case CatalogType.service:
        return 'Services';
      case CatalogType.property:
        return 'Immobilier';
    }
  }

  /// French singular label.
  String get singular {
    switch (this) {
      case CatalogType.product:
        return 'Produit';
      case CatalogType.service:
        return 'Service';
      case CatalogType.property:
        return 'Bien immobilier';
    }
  }

  IconData get icon {
    switch (this) {
      case CatalogType.product:
        return Icons.shopping_bag_outlined;
      case CatalogType.service:
        return Icons.handyman_outlined;
      case CatalogType.property:
        return Icons.home_work_outlined;
    }
  }

  /// A soft accent tint for this category, resolved against [colors] so it
  /// stays legible in both light and dark mode.
  Color tintOf(NovaColors colors) {
    switch (this) {
      case CatalogType.product:
        return colors.lavender;
      case CatalogType.service:
        return colors.butter;
      case CatalogType.property:
        return colors.blush;
    }
  }

  static CatalogType fromApi(String? value) {
    switch (value) {
      case 'service':
        return CatalogType.service;
      case 'property':
        return CatalogType.property;
      default:
        return CatalogType.product;
    }
  }
}

/// The sort options supported by `getListings(sort:)`.
enum CatalogSort { newest, priceAsc, priceDesc, popular }

extension CatalogSortX on CatalogSort {
  String get apiValue {
    switch (this) {
      case CatalogSort.newest:
        return 'newest';
      case CatalogSort.priceAsc:
        return 'price_asc';
      case CatalogSort.priceDesc:
        return 'price_desc';
      case CatalogSort.popular:
        return 'popular';
    }
  }

  String get label {
    switch (this) {
      case CatalogSort.newest:
        return 'Nouveautés';
      case CatalogSort.priceAsc:
        return 'Prix croissant';
      case CatalogSort.priceDesc:
        return 'Prix décroissant';
      case CatalogSort.popular:
        return 'Popularité';
    }
  }

  IconData get icon {
    switch (this) {
      case CatalogSort.newest:
        return Icons.auto_awesome_outlined;
      case CatalogSort.priceAsc:
        return Icons.arrow_upward_rounded;
      case CatalogSort.priceDesc:
        return Icons.arrow_downward_rounded;
      case CatalogSort.popular:
        return Icons.local_fire_department_outlined;
    }
  }
}

/// Picks a soft accent colour deterministically from a string seed,
/// resolved against [colors] for the active light/dark theme.
Color softTintFor(String seed, NovaColors colors) {
  final palette = [
    colors.lavender,
    colors.butter,
    colors.blush,
    colors.surfaceMuted,
  ];
  return palette[seed.hashCode.abs() % palette.length];
}

/// A pleasant rotating icon for a category, derived from its slug/name.
IconData categoryIcon(String slug, String type) {
  final s = '$slug ${type.toLowerCase()}'.toLowerCase();
  if (s.contains('hood') || s.contains('sweat')) {
    return Icons.dry_cleaning_rounded;
  }
  if (s.contains('denim') || s.contains('jean') || s.contains('vetement')) {
    return Icons.checkroom_rounded;
  }
  if (s.contains('shoe') || s.contains('chaussure')) {
    return Icons.ice_skating_rounded;
  }
  if (s.contains('tech') || s.contains('electro') || s.contains('phone')) {
    return Icons.devices_other_rounded;
  }
  if (s.contains('maison') || s.contains('home') || s.contains('deco')) {
    return Icons.chair_outlined;
  }
  if (s.contains('beaut') || s.contains('cosm')) {
    return Icons.spa_outlined;
  }
  if (s.contains('sport') || s.contains('fitness')) {
    return Icons.sports_basketball_outlined;
  }
  if (s.contains('service')) return Icons.handyman_outlined;
  if (s.contains('immo') || s.contains('property') || s.contains('apart')) {
    return Icons.home_work_outlined;
  }
  if (s.contains('food') || s.contains('aliment') || s.contains('epic')) {
    return Icons.restaurant_outlined;
  }
  return Icons.local_mall_outlined;
}

/// Formats a [Duration] as a `JJ:HH:MM:SS` style French countdown string.
String formatCountdown(Duration d) {
  if (d.isNegative) return 'Terminée';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  if (days > 0) {
    return '${days}j ${two(hours)}:${two(minutes)}:${two(seconds)}';
  }
  return '${two(hours)}:${two(minutes)}:${two(seconds)}';
}

/// A live, self-updating countdown chip toward [endAt].
class CountdownChip extends StatefulWidget {
  const CountdownChip({
    required this.endAt,
    this.background = AppColors.deepInk,
    this.foreground = AppColors.lime,
    this.icon = Icons.timer_outlined,
    super.key,
  });

  /// ISO-8601 string of the deadline, or null when unknown.
  final String? endAt;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  State<CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<CountdownChip> {
  Timer? _timer;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = DateTime.tryParse(widget.endAt ?? '');
    if (_deadline != null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = _deadline;
    final label = deadline == null
        ? 'Offre limitée'
        : formatCountdown(deadline.difference(DateTime.now()));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 13, color: widget.foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: widget.foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small pill that shows a discount percentage.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({required this.percent, super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '-$percent%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
