import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/delivery_driver.dart';
import '../../data/repositories/driver_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'delivery_widgets.dart';
import 'driver_format.dart';

/// The driver's earnings screen: total / weekly / monthly figures, pending
/// payout, an animated history chart and the recent payout list.
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  late Future<DriverEarnings> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DriverEarnings> _load() {
    return context.read<DriverRepository>().getEarnings();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<DriverEarnings>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ScreenHeader(title: 'Mes revenus'),
                ),
                Expanded(child: NovaLoadingView()),
              ],
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ScreenHeader(title: 'Mes revenus'),
                ),
                Expanded(
                  child: NovaErrorState(
                    message: error is RepositoryException
                        ? error.message
                        : 'Impossible de charger vos revenus.',
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: _EarningsBody(earnings: snapshot.data!),
          );
        },
      ),
    );
  }
}

class _EarningsBody extends StatelessWidget {
  const _EarningsBody({required this.earnings});

  final DriverEarnings earnings;

  @override
  Widget build(BuildContext context) {
    final history = earnings.earningsHistory;
    final maxPeriod = [
      earnings.weeklyEarnings,
      earnings.monthlyEarnings,
      earnings.totalEarnings,
    ].reduce((a, b) => a > b ? a : b);
    final safeMax = maxPeriod <= 0 ? 1.0 : maxPeriod;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        const ScreenHeader(title: 'Mes revenus'),
        const SizedBox(height: 16),
        _TotalCard(
          total: earnings.totalEarnings,
          pending: earnings.pendingPayout,
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Répartition'),
        const SizedBox(height: 8),
        NovaCard(
          child: Column(
            children: [
              DeliveryProgressRow(
                label: 'Cette semaine',
                value: earnings.weeklyEarnings,
                fraction: earnings.weeklyEarnings / safeMax,
                tint: AppColors.lime,
              ),
              const SizedBox(height: 14),
              DeliveryProgressRow(
                label: 'Ce mois-ci',
                value: earnings.monthlyEarnings,
                fraction: earnings.monthlyEarnings / safeMax,
                tint: AppColors.info,
              ),
              const SizedBox(height: 14),
              DeliveryProgressRow(
                label: 'Total cumulé',
                value: earnings.totalEarnings,
                fraction: earnings.totalEarnings / safeMax,
                tint: context.colors.textPrimary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Historique des gains'),
        const SizedBox(height: 8),
        NovaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${history.length} jour${history.length > 1 ? 's' : ''} suivi${history.length > 1 ? 's' : ''}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DeliveryBarChart(
                values: [for (final point in history) point.amount],
                labels: [
                  for (final point in history)
                    DeliveryFormat.weekdayLetter(point.date),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader(title: 'Versements récents'),
        const SizedBox(height: 8),
        if (earnings.recentPayouts.isEmpty)
          NovaCard(
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucun versement pour le moment. Vos gains apparaîtront '
                    'ici dès le premier paiement.',
                    style: AppTypography.bodyMuted,
                  ),
                ),
              ],
            ),
          )
        else
          ...earnings.recentPayouts.map(
            (payout) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PayoutRow(payout: payout),
            ),
          ),
      ]),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.pending});

  final double total;
  final double pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: AppColors.ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Revenus totaux',
                style: TextStyle(
                  color: Color(0xFFB9C0B7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            formatPrice(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C332E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: AppColors.lime,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'En attente de versement',
                    style: TextStyle(
                      color: Color(0xFFB9C0B7),
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  formatPrice(pending),
                  style: const TextStyle(
                    color: AppColors.lime,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.payout});

  final DriverPayout payout;

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
            child: Icon(
              Icons.payments_outlined,
              size: 20,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPrice(payout.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  DeliveryFormat.date(payout.date),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          NovaBadge(
            label: DeliveryFormat.payoutStatusLabel(payout.status),
            tone: DeliveryFormat.payoutTone(payout.status),
            dense: true,
          ),
        ],
      ),
    );
  }
}
