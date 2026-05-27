import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../reviews/reviews_screen.dart';
import '../reviews/write_review_screen.dart';
import '../shop/shop_tab.dart';
import 'product_detail_screen.dart';

/// Resolves the listing slug from a route argument, accepting either a
/// [ProductDetailArgs] or a raw [String] slug.
String _slugFrom(Object? arguments) {
  if (arguments is ProductDetailArgs) return arguments.slug;
  if (arguments is String) return arguments;
  if (arguments is Map && arguments['slug'] is String) {
    return arguments['slug'] as String;
  }
  return '';
}

/// Resolves a [ReviewsArgs] from a route argument.
ReviewsArgs _reviewsArgsFrom(Object? arguments) {
  if (arguments is ReviewsArgs) return arguments;
  return const ReviewsArgs(targetId: '', targetName: 'Produit');
}

/// Resolves a [WriteReviewArgs] from a route argument.
WriteReviewArgs _writeReviewArgsFrom(Object? arguments) {
  if (arguments is WriteReviewArgs) return arguments;
  if (arguments is ReviewsArgs) {
    return WriteReviewArgs(
      targetId: arguments.targetId,
      targetName: arguments.targetName,
      isVendor: arguments.isVendor,
    );
  }
  return const WriteReviewArgs(targetId: '', targetName: 'Produit');
}

/// Routes contributed by WS2 (produit, avis, catalogue).
final FeatureRoutes productRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.productDetail: (args) =>
      ProductDetailScreen(slug: _slugFrom(args)),
  RouteNames.shop: (_) => const ShopTab(),
  RouteNames.shopPage: (_) => const ShopTab(),
  RouteNames.reviews: (args) => ReviewsScreen(args: _reviewsArgsFrom(args)),
  RouteNames.writeReview: (args) =>
      WriteReviewScreen(args: _writeReviewArgsFrom(args)),
});
