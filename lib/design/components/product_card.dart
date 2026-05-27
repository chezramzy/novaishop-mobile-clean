import 'package:flutter/material.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import 'nova_image.dart';
import '../tokens/app_colors.dart';
import '../tokens/nova_colors.dart';

/// A compact, tappable product tile used across catalogue grids.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.listing,
    required this.onTap,
    this.onAdd,
    this.onFavorite,
    this.isFavorite = false,
    super.key,
  });

  final Listing listing;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: _tintFor(listing.id, colors),
                      child: NovaImage(
                        url: listing.displayImage,
                        fit: BoxFit.cover,
                        error: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _RoundMiniButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    onTap: onFavorite,
                    background: colors.surface,
                    foreground: colors.textPrimary,
                  ),
                ),
                if (listing.originalPrice != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          'PROMO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: _RoundMiniButton(
                    icon: Icons.add,
                    onTap: onAdd,
                    background: AppColors.deepInk,
                    foreground: AppColors.lime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            listing.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.1),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatPrice(listing.price),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (listing.originalPrice != null) ...[
                const SizedBox(width: 6),
                Text(
                  formatPrice(listing.originalPrice!),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    decoration: TextDecoration.lineThrough,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _tintFor(String value, NovaColors colors) {
    final tints = [
      colors.butter,
      colors.lavender,
      colors.blush,
      colors.surfaceMuted,
    ];
    return tints[value.hashCode.abs() % tints.length];
  }
}

class _RoundMiniButton extends StatelessWidget {
  const _RoundMiniButton({
    required this.icon,
    required this.onTap,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
      ),
    );
  }
}
