import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/coupon.dart';
import '../../data/repositories/coupon_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import 'widgets/seller_widgets.dart';

/// Lists the seller's coupons with create and deactivate actions.
class SellerCouponsScreen extends StatefulWidget {
  const SellerCouponsScreen({super.key});

  @override
  State<SellerCouponsScreen> createState() => _SellerCouponsScreenState();
}

class _SellerCouponsScreenState extends State<SellerCouponsScreen> {
  late Future<List<Coupon>> _future;
  String? _busyCouponId;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Coupon>> _load() => context.read<CouponRepository>().getCoupons();

  void _reload() => setState(() => _future = _load());

  Future<void> _openCreate() async {
    final created =
        await Navigator.of(context).pushNamed(RouteNames.createCoupon);
    if (created == true && mounted) _reload();
  }

  Future<void> _deactivate(Coupon coupon) async {
    setState(() => _busyCouponId = coupon.id);
    try {
      await context.read<CouponRepository>().deactivateCoupon(coupon.id);
      if (!mounted) return;
      showSellerSnack(context, 'Coupon « ${coupon.code} » désactivé.');
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSellerSnack(
          context,
          'Désactivation impossible. Réessayez.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busyCouponId = null);
    }
  }

  void _confirmDeactivate(Coupon coupon) {
    showNovaSheet<void>(
      context: context,
      title: 'Désactiver le coupon',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Le coupon « ${coupon.code} » ne pourra plus être utilisé par '
            'les clients. Cette action est définitive.',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: 'Désactiver le coupon',
            icon: Icons.block_rounded,
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _deactivate(coupon);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          NovaButton.ghost(
            label: 'Annuler',
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        backgroundColor: AppColors.deepInk,
        foregroundColor: AppColors.lime,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nouveau coupon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(title: 'Mes coupons'),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: FutureBuilder<List<Coupon>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const NovaLoadingView(
                    label: 'Chargement des coupons…',
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return NovaErrorState(
                    message: error is RepositoryException
                        ? error.message
                        : 'Impossible de charger les coupons.',
                    onRetry: _reload,
                  );
                }
                final coupons = snapshot.requireData;
                if (coupons.isEmpty) {
                  return NovaEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'Aucun coupon',
                    message: 'Créez des coupons de réduction pour fidéliser '
                        'vos clients.',
                    actionLabel: 'Créer un coupon',
                    onAction: _openCreate,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.deepInk,
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) => StaggeredEntrance.item(
                      index,
                      _CouponCard(
                        coupon: coupons[index],
                        busy: _busyCouponId == coupons[index].id,
                        onDeactivate: () => _confirmDeactivate(coupons[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.busy,
    required this.onDeactivate,
  });

  final Coupon coupon;
  final bool busy;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final value = coupon.isPercentage
        ? '${coupon.discountValue.toStringAsFixed(0)} %'
        : formatPrice(coupon.discountValue);
    final usesLabel = coupon.maxUses > 0
        ? '${coupon.usedCount}/${coupon.maxUses} utilisations'
        : '${coupon.usedCount} utilisations';

    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: coupon.active
                      ? AppColors.lime
                      : context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: coupon.active
                      ? AppColors.ink
                      : context.colors.textPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: .5,
                      ),
                    ),
                    Text(
                      '$value de réduction',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              NovaBadge(
                label: coupon.active ? 'Actif' : 'Inactif',
                tone: coupon.active
                    ? NovaBadgeTone.success
                    : NovaBadgeTone.neutral,
                dense: true,
              ),
            ],
          ),
          Divider(height: AppSpacing.lg, color: context.colors.border),
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 15, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                usesLabel,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (coupon.minOrderAmount > 0)
                Text(
                  'Min. ${formatPrice(coupon.minOrderAmount)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (coupon.active) ...[
            const SizedBox(height: AppSpacing.xs),
            NovaButton.ghost(
              label: 'Désactiver',
              icon: Icons.block_rounded,
              busy: busy,
              onPressed: onDeactivate,
            ),
          ],
        ],
      ),
    );
  }
}
