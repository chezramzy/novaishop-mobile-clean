import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/delivery_driver.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'delivery_widgets.dart';
import 'driver_format.dart';

/// The driver's "Tournée" tab: the dashboard. Shows today's stats, the
/// active deliveries and a weekly earnings trend. When the user has no
/// driver profile yet, a "Devenir livreur" call-to-action is shown.
class DriverHomeTab extends StatefulWidget {
  const DriverHomeTab({super.key});

  @override
  State<DriverHomeTab> createState() => _DriverHomeTabState();
}

class _DriverHomeTabState extends State<DriverHomeTab> {
  late Future<DriverDashboardSummary?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DriverDashboardSummary?> _load() {
    return context.read<DriverRepository>().getDashboard();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _openRegister() async {
    final result = await Navigator.of(context).pushNamed(
      RouteNames.driverRegister,
    );
    if (result != null && mounted) _reload();
  }

  Future<void> _openDetail(String deliveryId) async {
    await Navigator.of(context).pushNamed(
      RouteNames.deliveryDetail,
      arguments: deliveryId,
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<DriverDashboardSummary?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovaLoadingView();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return NovaErrorState(
              message: error is RepositoryException
                  ? error.message
                  : 'Impossible de charger votre tableau de bord.',
              onRetry: _reload,
            );
          }
          final dashboard = snapshot.data;
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: dashboard == null
                ? _BecomeDriverView(onRegister: _openRegister)
                : _DashboardView(
                    dashboard: dashboard,
                    onOpenDelivery: _openDetail,
                    onOpenEarnings: () => Navigator.of(context)
                        .pushNamed(RouteNames.driverEarnings),
                    onOpenDeliveries: () => Navigator.of(context)
                        .pushNamed(RouteNames.driverDeliveries),
                  ),
          );
        },
      ),
    );
  }
}

/* ----------------------- not a driver yet ----------------------- */

class _BecomeDriverView extends StatelessWidget {
  const _BecomeDriverView({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const ScreenHeader(title: 'Tournée', showBack: false),
        const SizedBox(height: 32),
        Center(
          child: Container(
            height: 100,
            width: 100,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 50,
              color: AppColors.ink,
            ),
          ).popIn(),
        ),
        const SizedBox(height: 22),
        Text(
          'Devenez livreur NovAiShop',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ).fadeSlideIn(),
        const SizedBox(height: 10),
        Text(
          'Vous n\'avez pas encore de profil livreur. Créez-le en quelques '
          'minutes pour recevoir des courses et générer des revenus à votre '
          'rythme.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMuted,
        ).fadeSlideIn(delay: AppMotion.fast),
        const SizedBox(height: 24),
        ...StaggeredEntrance.all([
          const _PerkRow(
            icon: Icons.schedule_rounded,
            title: 'Horaires flexibles',
            subtitle: 'Livrez quand vous le souhaitez.',
          ),
          const SizedBox(height: 10),
          const _PerkRow(
            icon: Icons.payments_outlined,
            title: 'Revenus transparents',
            subtitle: 'Suivez vos gains en temps réel.',
          ),
          const SizedBox(height: 10),
          const _PerkRow(
            icon: Icons.map_outlined,
            title: 'Courses près de vous',
            subtitle: 'Des livraisons assignées automatiquement.',
          ),
        ], baseDelay: AppMotion.normal),
        const SizedBox(height: 24),
        NovaButton.primary(
          label: 'Devenir livreur',
          icon: Icons.arrow_forward_rounded,
          onPressed: onRegister,
        ),
      ],
    );
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: context.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 20, color: context.colors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* --------------------------- dashboard --------------------------- */

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.dashboard,
    required this.onOpenDelivery,
    required this.onOpenEarnings,
    required this.onOpenDeliveries,
  });

  final DriverDashboardSummary dashboard;
  final void Function(String) onOpenDelivery;
  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenDeliveries;

  @override
  Widget build(BuildContext context) {
    final stats = dashboard.todayStats;
    final active = dashboard.activeDeliveries;
    final weekly = dashboard.weeklyEarnings;
    final weekTotal =
        weekly.fold<double>(0, (sum, point) => sum + point.amount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        ScreenHeader(
          title: 'Tournée',
          showBack: false,
          trailing: CircleIconButton(
            icon: Icons.account_balance_wallet_outlined,
            onPressed: onOpenEarnings,
            tooltip: 'Mes revenus',
          ),
        ),
        const SizedBox(height: 16),
        DriverProfileCard(driver: dashboard.driver),
        const SizedBox(height: 16),
        Text("Aujourd'hui", style: AppTypography.subtitle),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DeliveryStatTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Livrées',
                value: '${stats.completed}',
                tint: AppColors.lavender,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DeliveryStatTile(
                icon: Icons.euro_rounded,
                label: 'Gains',
                value: formatPrice(stats.earnings),
                tint: AppColors.butter,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DeliveryStatTile(
                icon: Icons.star_outline_rounded,
                label: 'Note',
                value: stats.avgRating.toStringAsFixed(1),
                tint: AppColors.blush,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EarningsSnapshot(
          weekTotal: weekTotal,
          onTap: onOpenEarnings,
        ),
        const SizedBox(height: 16),
        if (weekly.isNotEmpty) ...[
          NovaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text('Tendance de la semaine',
                        style: AppTypography.subtitle),
                  ],
                ),
                const SizedBox(height: 14),
                DeliveryBarChart(
                  values: [for (final point in weekly) point.amount],
                  labels: [
                    for (final point in weekly)
                      DeliveryFormat.weekdayLetter(point.date),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SectionHeader(
          title: 'Livraisons en cours',
          actionLabel: 'Tout voir',
          onAction: onOpenDeliveries,
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          NovaCard(
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.inbox_outlined,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aucune livraison en cours. Une nouvelle course vous '
                    'sera assignée prochainement.',
                    style: AppTypography.bodyMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...active.map(
            (delivery) => DeliveryListCard(
              delivery: delivery,
              onTap: () => onOpenDelivery(delivery.id),
            ),
          ),
      ]),
    );
  }
}

class _EarningsSnapshot extends StatelessWidget {
  const _EarningsSnapshot({required this.weekTotal, required this.onTap});

  final double weekTotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      onTap: onTap,
      color: AppColors.deepInk,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.savings_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gains de la semaine',
                  style: TextStyle(
                    color: Color(0xFFB9C0B7),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPrice(weekTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.lime,
          ),
        ],
      ),
    );
  }
}
