import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../categories/categories_screen.dart';
import 'catalog_screen.dart';
import 'category_listings_screen.dart';
import 'flash_sales_screen.dart';
import 'search_screen.dart';

/// Routes contributed by WS1 (découverte & catalogue).
final FeatureRoutes discoveryRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.catalog: (_) => const CatalogScreen(),
  RouteNames.categories: (_) => const CategoriesScreen(),
  RouteNames.categoryListings: (args) => CategoryListingsScreen(
        args: args is CategoryListingsArgs
            ? args
            : const CategoryListingsArgs(title: 'Catégorie'),
      ),
  RouteNames.search: (_) => const SearchScreen(),
  RouteNames.flashSales: (_) => const FlashSalesScreen(),
});
