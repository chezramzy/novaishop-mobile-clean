import 'package:flutter/material.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/delivery.dart';
import '../../data/models/delivery_driver.dart';
import '../../design/design_system.dart';
import 'driver_format.dart';

/// A compact statistic tile (icon, value, label) on a tinted surface.
class DeliveryStatTile extends StatelessWidget {
  const DeliveryStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NovaCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: colors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// A tappable summary row for a single delivery.
class DeliveryListCard extends StatelessWidget {
  const DeliveryListCard({
    required this.delivery,
    required this.onTap,
    super.key,
  });

  final Delivery delivery;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final itemCount =
        delivery.items.fold<int>(0, (sum, item) => sum + item.quantity);
    return NovaCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.customerName.isEmpty
                          ? 'Client'
                          : delivery.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Commande #${_shortId(delivery.orderId)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              NovaStatusBadge(status: delivery.status, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          _Leg(
            icon: Icons.store_mall_directory_outlined,
            tint: colors.butter,
            label: 'Retrait',
            value: '${delivery.pickupAddress}, ${delivery.pickupCity}',
          ),
          const SizedBox(height: 8),
          _Leg(
            icon: Icons.location_on_outlined,
            tint: colors.lavender,
            label: 'Livraison',
            value: '${delivery.deliveryAddress}, ${delivery.deliveryCity}',
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 15,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '$itemCount article${itemCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Gain : ',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                formatPrice(delivery.driverEarning),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _shortId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }
}

class _Leg extends StatelessWidget {
  const _Leg({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: colors.textPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A driver identity card used on the dashboard header.
class DriverProfileCard extends StatelessWidget {
  const DriverProfileCard({required this.driver, super.key});

  final DeliveryDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              DeliveryFormat.vehicleIcon(driver.vehicleType),
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName.isEmpty ? 'Livreur' : driver.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.lime,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      driver.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${driver.totalDeliveries} livraisons',
                      style: const TextStyle(
                        color: Color(0xFFB9C0B7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          NovaStatusBadge(status: driver.status, dense: true),
        ],
      ),
    );
  }
}

/// A lightweight bar chart, drawn with plain Flutter widgets (no package).
///
/// Each bar's height is proportional to its value relative to the series
/// maximum; the tallest bar is highlighted.
class DeliveryBarChart extends StatelessWidget {
  const DeliveryBarChart({
    required this.values,
    required this.labels,
    this.height = 130,
    this.barColor = AppColors.lime,
    this.trackColor,
    super.key,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color barColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final effectiveTrack = trackColor ?? context.colors.surfaceMuted;
    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Aucune donnée à afficher.',
            style: AppTypography.caption,
          ),
        ),
      );
    }
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final peakIndex = values.indexOf(maxValue);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Bar(
                  fraction: (values[i] / safeMax).clamp(0.0, 1.0),
                  label: i < labels.length ? labels[i] : '',
                  highlighted: i == peakIndex && maxValue > 0,
                  barColor: barColor,
                  trackColor: effectiveTrack,
                  delay: AppMotion.stagger * i,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.label,
    required this.highlighted,
    required this.barColor,
    required this.trackColor,
    required this.delay,
  });

  final double fraction;
  final String label;
  final bool highlighted;
  final Color barColor;
  final Color trackColor;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fillHeight = (constraints.maxHeight * fraction)
                  .clamp(4.0, double.infinity);
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fillHeight),
                    duration: AppMotion.slow,
                    curve: AppMotion.standard,
                    builder: (context, value, _) {
                      return Container(
                        height: value,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: highlighted
                              ? barColor
                              : barColor.withValues(alpha: .45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: 10,
            fontWeight: highlighted ? FontWeight.w900 : FontWeight.w600,
            color: highlighted
                ? context.colors.textPrimary
                : context.colors.textSecondary,
          ),
        ),
      ],
    ).fadeSlideIn(delay: delay);
  }
}

/// A horizontal sparkline-style progress row: a labelled value with a
/// proportional fill bar. Used in the earnings breakdown.
class DeliveryProgressRow extends StatelessWidget {
  const DeliveryProgressRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.tint,
    super.key,
  });

  final String label;
  final double value;
  final double fraction;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              formatPrice(value),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 8, color: context.colors.surfaceMuted),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                duration: AppMotion.slow,
                curve: AppMotion.standard,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 8, color: tint),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
