import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/seller_analytics.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'widgets/seller_charts.dart';
import 'widgets/seller_widgets.dart';

/// The seller analytics dashboard: revenue trend, key totals, best sellers,
/// stock levels and order-status distribution — all rendered with the
/// dependency-free charts in `widgets/seller_charts.dart`.
class SellerAnalyticsScreen extends StatefulWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  State<SellerAnalyticsScreen> createState() => _SellerAnalyticsScreenState();
}

class _SellerAnalyticsScreenState extends State<SellerAnalyticsScreen> {
  late Future<SellerAnalytics> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SellerAnalytics> _load() {
    final repository = SellerRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    return repository.getAnalytics();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<SellerAnalytics>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovaLoadingView(
              label: 'Chargement des statistiques…',
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return NovaErrorState(
              message: error is RepositoryException
                  ? error.message
                  : 'Impossible de charger les statistiques.',
              onRetry: _reload,
            );
          }
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: _AnalyticsBody(analytics: snapshot.requireData),
          );
        },
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.analytics});

  final SellerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final series = analytics.revenueTimeSeries;
    final hasData = series.isNotEmpty ||
        analytics.totalOrders > 0 ||
        analytics.bestSellers.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        const ScreenHeader(title: 'Statistiques'),
        const SizedBox(height: AppSpacing.md),
        if (!hasData)
          const _NoDataNote()
        else ...[
          Row(
            children: [
              Expanded(
                child: SellerStatCard(
                  icon: Icons.euro_rounded,
                  label: 'Revenu total',
                  value: formatPrice(analytics.totalRevenue),
                  tint: AppColors.lime,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SellerStatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Commandes',
                  value: '${analytics.totalOrders}',
                  tint: AppColors.lavender,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SellerStatCard(
                  icon: Icons.shopping_cart_checkout_rounded,
                  label: 'Panier moyen',
                  value: formatPrice(analytics.averageOrderValue),
                  tint: AppColors.butter,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SellerPanel(
            title: 'Évolution du chiffre d\'affaires',
            icon: Icons.show_chart_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SellerSparkline(
                  values: series.map((point) => point.amount).toList(),
                  color: context.colors.textPrimary,
                ),
                if (series.length >= 2) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _shortDate(series.first.date),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _shortDate(series.last.date),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (analytics.bestSellers.isNotEmpty) ...[
            SellerPanel(
              title: 'Meilleures ventes',
              icon: Icons.star_outline_rounded,
              child: Column(
                children: [
                  SellerBarChart(
                    height: 150,
                    valueLabel: (value) => value.round().toString(),
                    data: [
                      for (final seller in analytics.bestSellers.take(6))
                        SellerBarDatum(
                          label: _truncate(seller.title),
                          value: seller.unitsSold.toDouble(),
                          color: context.colors.textPrimary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final seller in analytics.bestSellers.take(5))
                    _BestSellerRow(stat: seller),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (analytics.orderStatusDistribution.isNotEmpty) ...[
            SellerPanel(
              title: 'Répartition des commandes',
              icon: Icons.donut_small_outlined,
              child: Column(
                children: [
                  for (final entry in analytics.orderStatusDistribution)
                    SellerProportionBar(
                      label: _statusLabel(entry.status),
                      value: entry.count,
                      total: _statusTotal(analytics.orderStatusDistribution),
                      color: _statusColor(entry.status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (analytics.stockLevels.isNotEmpty)
            SellerPanel(
              title: 'Niveaux de stock',
              icon: Icons.warehouse_outlined,
              child: Column(
                children: [
                  for (final stock in analytics.stockLevels.take(8))
                    _StockRow(stat: stock),
                ],
              ),
            ),
        ],
      ]),
    );
  }

  static int _statusTotal(List<StatusCount> entries) =>
      entries.fold<int>(0, (sum, entry) => sum + entry.count);

  static String _truncate(String value) =>
      value.length > 10 ? '${value.substring(0, 9)}…' : value;

  static String _shortDate(String iso) {
    if (iso.length >= 10) return iso.substring(0, 10);
    return iso;
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payées';
      case 'processing':
        return 'En préparation';
      case 'shipped':
        return 'Expédiées';
      case 'delivered':
        return 'Livrées';
      case 'refunded':
        return 'Remboursées';
      case 'cancelled':
        return 'Annulées';
      default:
        return status;
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'refunded':
        return AppColors.danger;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }
}

class _NoDataNote extends StatelessWidget {
  const _NoDataNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: NovaEmptyState(
        icon: Icons.insights_outlined,
        title: 'Pas encore de statistiques',
        message: 'Vos statistiques de ventes apparaîtront ici dès vos '
            'premières commandes.',
      ),
    );
  }
}

class _BestSellerRow extends StatelessWidget {
  const _BestSellerRow({required this.stat});

  final BestSellerStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          NovaBadge(label: '${stat.unitsSold} vendus', dense: true),
          const SizedBox(width: 6),
          Text(
            formatPrice(stat.revenue),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stat});

  final StockLevelStat stat;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (stat.status) {
      'out' => ('Épuisé', NovaBadgeTone.danger),
      'low' => ('Stock bas', NovaBadgeTone.warning),
      _ => ('En stock', NovaBadgeTone.success),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              stat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${stat.inventory} u.',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 6),
          NovaBadge(label: label, tone: tone, dense: true),
        ],
      ),
    );
  }
}
