import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../assistant/assistant_tab.dart';
import 'delivery_detail_screen.dart';
import 'driver_deliveries_tab.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_tab.dart';
import 'driver_register_screen.dart';

/// Routes contributed by WS8 (livraison & assistant IA).
final FeatureRoutes deliveryRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.driverHome: (_) => const DriverHomeTab(),
  RouteNames.driverRegister: (_) => const DriverRegisterScreen(),
  RouteNames.driverDeliveries: (_) => const DriverDeliveriesTab(),
  RouteNames.deliveryDetail: (args) =>
      DeliveryDetailScreen(deliveryId: args is String ? args : ''),
  RouteNames.driverEarnings: (_) => const DriverEarningsScreen(),
  RouteNames.assistant: (_) => const AssistantTab(),
});
