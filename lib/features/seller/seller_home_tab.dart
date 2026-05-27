import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/models/order.dart';
import '../../data/models/seller_dashboard.dart';
import '../../data/repositories/partner_application_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../../design/components/nova_image.dart';
import '../auth/auth_controller.dart';
import 'seller_order_detail_screen.dart';
import 'widgets/seller_widgets.dart';

/// The seller dashboard — the "Ventes" tab. Shows the shop status, KYC
/// banner, key metrics, quick actions and recent orders/products. When the
/// seller has no shop yet, a creation CTA is shown instead.
class SellerHomeTab extends StatefulWidget {
  const SellerHomeTab({super.key});

  @override
  State<SellerHomeTab> createState() => _SellerHomeTabState();
}

class _SellerHomeTabState extends State<SellerHomeTab> {
  late Future<SellerDashboardSummary?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SellerDashboardSummary?> _load() {
    final auth = context.read<AuthController>();
    final applications = context.read<PartnerApplicationRepository>();
    final repository = SellerRepository(
      accessToken: auth.accessToken,
    );
    return repository.getDashboard().then((dashboard) async {
      if (dashboard != null) return dashboard;
      final application =
          await applications.getLatestForUser(auth.user?.id ?? '');
      if (application?['status'] == 'approved') {
        return repository.ensureApprovedPartnerDashboard();
      }
      return null;
    });
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _openAndReload(String route, {Object? arguments}) async {
    final result =
        await Navigator.of(context).pushNamed(route, arguments: arguments);
    if (result == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<SellerDashboardSummary?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovaLoadingView(label: 'Chargement de votre espace…');
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return NovaErrorState(
              message: error is RepositoryException
                  ? error.message
                  : error is SellerException
                      ? error.message
                      : 'Impossible de charger votre espace partenaire.',
              onRetry: _reload,
            );
          }
          final dashboard = snapshot.data;
          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: dashboard == null
                ? const _NoApprovedPartnerView()
                : _DashboardView(
                    dashboard: dashboard,
                    onOpen: _openAndReload,
                  ),
          );
        },
      ),
    );
  }
}

/* ------------------------------ no shop yet ----------------------------- */

class _NoApprovedPartnerView extends StatelessWidget {
  const _NoApprovedPartnerView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const ScreenHeader(title: 'Espace partenaire', showBack: false),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Container(
            height: 104,
            width: 104,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 52,
              color: AppColors.ink,
            ),
          ).popIn(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ouvrez votre espace partenaire',
          textAlign: TextAlign.center,
          style: AppTypography.headline,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Une demande approuvee est necessaire avant d ajouter des produits.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        NovaButton.primary(
          label: 'Voir ma demande',
          icon: Icons.add_business_outlined,
          onPressed: () =>
              Navigator.of(context).pushNamed(RouteNames.partnerApplication),
        ),
        const SizedBox(height: AppSpacing.md),
        const NovaCard(
          color: AppColors.deepInk,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apres validation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              _SellingPoint(
                icon: Icons.auto_awesome_outlined,
                text: 'Vous ajoutez directement vos produits au catalogue.',
              ),
              _SellingPoint(
                icon: Icons.insights_outlined,
                text: 'Vous suivez vos produits, stocks et ventes.',
              ),
              _SellingPoint(
                icon: Icons.verified_user_outlined,
                text: 'NovaShop reste la seule marque visible cote client.',
              ),
            ],
          ),
        ),
      ].map((w) => w).toList(),
    );
  }
}

class _SellingPoint extends StatelessWidget {
  const _SellingPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.lime),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------- dashboard ------------------------------ */

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.dashboard, required this.onOpen});

  final SellerDashboardSummary dashboard;
  final void Function(String route, {Object? arguments}) onOpen;

  double get _revenue => dashboard.pendingPayouts
      .fold<double>(0, (sum, payout) => sum + payout.vendorAllocation);

  @override
  Widget build(BuildContext context) {
    final vendor = dashboard.vendor;
    final kycPending = vendor.kycStatus != 'approved';
    final recentOrders = dashboard.activeOrders.take(4).toList();
    final recentListings = dashboard.listings.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        const ScreenHeader(title: 'Espace partenaire', showBack: false),
        const SizedBox(height: AppSpacing.md),
        _PartnerHeaderCard(approved: vendor.isApproved),
        if (kycPending) ...[
          const SizedBox(height: AppSpacing.sm),
          _KycBanner(
            status: vendor.kycStatus,
            documentCount: dashboard.kycDocuments.length,
            onTap: () => onOpen(RouteNames.sellerKyc, arguments: dashboard),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SellerStatCard(
                icon: Icons.inventory_2_outlined,
                label: 'Produits',
                value: '${dashboard.totalListings}',
                tint: AppColors.lavender,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SellerStatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Commandes',
                value: '${dashboard.activeOrders.length}',
                tint: AppColors.blush,
                onTap: () => onOpen(RouteNames.sellerOrders,
                    arguments: dashboard.vendor.id),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: SellerStatCard(
                icon: Icons.payments_outlined,
                label: 'À encaisser',
                value: formatPrice(_revenue),
                tint: AppColors.butter,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Actions rapides',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          childAspectRatio: .92,
          children: [
            SellerActionTile(
              icon: Icons.add_box_outlined,
              label: 'Ajouter\nun produit',
              tint: context.colors.lavender,
              onTap: () => onOpen(RouteNames.addProduct),
            ),
            SellerActionTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Fiche IA',
              tint: AppColors.lime,
              onTap: () => onOpen(RouteNames.aiListingGenerator),
            ),
            SellerActionTile(
              icon: Icons.insights_outlined,
              label: 'Statistiques',
              tint: context.colors.butter,
              onTap: () => onOpen(RouteNames.sellerAnalytics),
            ),
            SellerActionTile(
              icon: Icons.receipt_long_outlined,
              label: 'Commandes',
              tint: context.colors.blush,
              onTap: () =>
                  onOpen(RouteNames.sellerOrders, arguments: vendor.id),
            ),
            SellerActionTile(
              icon: Icons.local_offer_outlined,
              label: 'Coupons',
              tint: context.colors.surfaceMuted,
              onTap: () => onOpen(RouteNames.sellerCoupons),
            ),
            SellerActionTile(
              icon: Icons.badge_outlined,
              label: 'Statut\npartenaire',
              tint: context.colors.lavender,
              onTap: () => onOpen(RouteNames.partnerApplication),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SellerPanel(
          title: 'Commandes récentes',
          icon: Icons.receipt_long_outlined,
          trailing: recentOrders.isEmpty
              ? null
              : _PanelLink(
                  label: 'Tout voir',
                  onTap: () =>
                      onOpen(RouteNames.sellerOrders, arguments: vendor.id),
                ),
          child: recentOrders.isEmpty
              ? const _PanelEmpty(
                  icon: Icons.inbox_outlined,
                  message: 'Aucune commande en cours.',
                )
              : Column(
                  children: [
                    for (final order in recentOrders)
                      _RecentOrderRow(
                        order: order,
                        onTap: () => onOpen(
                          RouteNames.sellerOrderDetail,
                          arguments: SellerOrderDetailArgs(
                            order: order,
                            vendorId: vendor.id,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SellerPanel(
          title: 'Mes produits',
          icon: Icons.inventory_2_outlined,
          trailing: _PanelLink(
            label: 'Ajouter',
            onTap: () => onOpen(RouteNames.addProduct),
          ),
          child: recentListings.isEmpty
              ? const _PanelEmpty(
                  icon: Icons.inventory_2_outlined,
                  message: 'Aucun produit. Ajoutez votre premier article.',
                )
              : Column(
                  children: [
                    for (final listing in recentListings)
                      _ProductRow(
                        listing: listing,
                        onTap: () => onOpen(
                          RouteNames.editProduct,
                          arguments: listing,
                        ),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _PartnerHeaderCard extends StatelessWidget {
  const _PartnerHeaderCard({required this.approved});

  final bool approved;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.storefront_rounded, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catalogue partenaire',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    'Produits visibles sous la marque NovaShop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.lime,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                NovaBadge(
                  label: approved ? 'Espace actif' : 'Espace en validation',
                  tone:
                      approved ? NovaBadgeTone.primary : NovaBadgeTone.warning,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KycBanner extends StatelessWidget {
  const _KycBanner({
    required this.status,
    required this.documentCount,
    required this.onTap,
  });

  final String status;
  final int documentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      'rejected' =>
        'Vos documents ont été refusés. Renvoyez vos justificatifs.',
      'under_review' ||
      'submitted' =>
        'Vos documents KYC sont en cours de vérification.',
      _ => documentCount == 0
          ? 'Envoyez vos documents KYC pour activer les versements.'
          : 'Complétez votre vérification KYC pour activer les versements.',
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.butter,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.warning.withValues(alpha: .4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelLink extends StatelessWidget {
  const _PanelLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        foregroundColor: context.colors.textPrimary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
      child: Text(label),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 22),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 18, color: context.colors.textPrimary),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commande #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${order.itemCount} article(s) · ${formatPrice(order.total)}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            NovaStatusBadge(status: order.status, dense: true),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: NovaImage(
                url: listing.displayImage,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: const ColoredBox(color: AppColors.butter),
                error: const ColoredBox(
                  color: AppColors.butter,
                  child: Icon(Icons.image_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${formatPrice(listing.price)} · Stock ${listing.inventory}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            NovaStatusBadge(status: listing.status, dense: true),
          ],
        ),
      ),
    );
  }
}
