import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../addresses/add_address_screen.dart';
import '../addresses/addresses_screen.dart';
import '../wishlist/wishlist_screen.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';
import 'step_tracker_screen.dart';

/// Routes contributed by WS4 (commandes, favoris, adresses).
final FeatureRoutes ordersRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.orders: (_) => const OrdersScreen(),
  RouteNames.orderDetail: (args) =>
      OrderDetailScreen(orderId: args is String ? args : ''),
  RouteNames.orderTracking: (args) =>
      StepTrackerScreen(orderId: args is String ? args : ''),
  RouteNames.wishlist: (_) => const WishlistScreen(),
  RouteNames.addresses: (_) => const AddressesScreen(),
  RouteNames.addAddress: (_) => const AddAddressScreen(),
});
