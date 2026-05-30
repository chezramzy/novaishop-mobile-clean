import 'package:flutter/material.dart';

import '../../design/design_system.dart';

/// A read-only row of five stars rendering a fractional [rating].
class StarRating extends StatelessWidget {
  const StarRating({
    required this.rating,
    this.size = 16,
    this.color = const Color(0xFFE0A106),
    super.key,
  });

  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = rating - index;
        IconData icon;
        if (filled >= 1) {
          icon = Icons.star_rounded;
        } else if (filled >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

/// An interactive star picker used inside the write-review sheet.
class StarSelector extends StatelessWidget {
  const StarSelector({
    required this.value,
    required this.onChanged,
    this.size = 40,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final star = index + 1;
        final selected = star <= value;
        return GestureDetector(
          onTap: () => onChanged(star),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedScale(
              scale: selected ? 1 : 0.86,
              duration: AppMotion.fast,
              curve: AppMotion.emphasized,
              child: Icon(
                selected ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: selected ? AppColors.warning : AppColors.muted,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Maps a 1-5 rating to a French label.
String ratingLabel(int rating) {
  switch (rating) {
    case 5:
      return 'Excellent';
    case 4:
      return 'Très bien';
    case 3:
      return 'Correct';
    case 2:
      return 'Décevant';
    case 1:
      return 'Mauvais';
    default:
      return 'Votre note';
  }
}

/// Formats an ISO date string into a short French date (« 22 mai 2026 »).
String formatReviewDate(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

/// A single review card showing author initials, rating, date and comment.
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    super.key,
  });

  final String authorName;
  final int rating;
  final String comment;
  final String createdAt;

  String get _initials {
    final parts = authorName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.lavender,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName.isEmpty ? 'Client NovaShop' : authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatReviewDate(createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              StarRating(rating: rating.toDouble()),
            ],
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment.trim(),
              style: TextStyle(color: colors.textSecondary, height: 1.45),
            ),
          ],
        ],
      ),
    );
  }
}

/// A compact rating summary block: big average, stars and review count.
class RatingSummary extends StatelessWidget {
  const RatingSummary({
    required this.average,
    required this.count,
    super.key,
  });

  final double average;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              average <= 0 ? '—' : average.toStringAsFixed(1),
              style: AppTypography.display,
            ),
            const SizedBox(height: 2),
            StarRating(rating: average, size: 18),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            count == 0
                ? 'Aucun avis pour le moment.'
                : count == 1
                    ? 'Basé sur 1 avis client.'
                    : 'Basé sur $count avis clients.',
            style: TextStyle(color: context.colors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
