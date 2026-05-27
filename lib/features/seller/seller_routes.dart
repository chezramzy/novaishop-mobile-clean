import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../../data/models/listing.dart';
import '../../data/models/seller_dashboard.dart';
import 'add_product_screen.dart';
import 'ai_listing_generator_screen.dart';
import 'create_coupon_screen.dart';
import 'seller_analytics_screen.dart';
import 'seller_coupons_screen.dart';
import 'seller_home_tab.dart';
import 'seller_hub_screen.dart';
import 'seller_kyc_screen.dart';
import 'seller_order_detail_screen.dart';
import 'seller_orders_screen.dart';

/// Routes contributed by WS7 (espace partenaire).
final FeatureRoutes sellerRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.sellerHub: (_) => const SellerHubScreen(),
  RouteNames.partnerHub: (_) => const SellerHubScreen(),
  RouteNames.sellerHome: (_) => const SellerHomeTab(),
  RouteNames.partnerHome: (_) => const SellerHomeTab(),
  RouteNames.createShop: (_) => const SellerHomeTab(),
  RouteNames.partnerCreateProfile: (_) => const SellerHomeTab(),
  RouteNames.editShop: (_) => const SellerHomeTab(),
  RouteNames.partnerEditProfile: (_) => const SellerHomeTab(),
  RouteNames.addProduct: (args) => AddProductScreen(
        shopId: args is String ? args : null,
      ),
  RouteNames.partnerAddProduct: (args) => AddProductScreen(
        shopId: args is String ? args : null,
      ),
  RouteNames.editProduct: (args) => AddProductScreen(
        listing: args is Listing ? args : null,
      ),
  RouteNames.partnerEditProduct: (args) => AddProductScreen(
        listing: args is Listing ? args : null,
      ),
  RouteNames.aiListingGenerator: (args) => AiListingGeneratorScreen(
        shopId: args is String ? args : '',
      ),
  RouteNames.sellerOrders: (args) => SellerOrdersScreen(
        vendorId: args is String ? args : '',
      ),
  RouteNames.sellerOrderDetail: (args) => args is SellerOrderDetailArgs
      ? SellerOrderDetailScreen(args: args)
      : const _SellerRouteError(
          message: 'Commande introuvable.',
        ),
  RouteNames.sellerAnalytics: (_) => const SellerAnalyticsScreen(),
  RouteNames.sellerCoupons: (_) => const SellerCouponsScreen(),
  RouteNames.createCoupon: (_) => const CreateCouponScreen(),
  RouteNames.sellerKyc: (args) => SellerKycScreen(
        dashboard: args is SellerDashboardSummary ? args : null,
      ),
});

/// Fallback shown when a seller route is opened without its required
/// arguments (e.g. a deep link to an order detail).
class _SellerRouteError extends StatelessWidget {
  const _SellerRouteError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace partenaire')),
      body: Center(child: Text(message)),
    );
  }
}
