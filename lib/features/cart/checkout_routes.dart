import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../checkout/order_confirmation_screen.dart';
import '../messages/order_conversation_screen.dart';
import 'cart_screen.dart';

/// Routes contributed by the cart/order-message flow.
final FeatureRoutes checkoutRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.cart: (_) => const CartScreen(),
  RouteNames.orderConversation: (args) {
    if (args is OrderConversationArgs) {
      return OrderConversationScreen(conversation: args.conversation);
    }
    return const CartScreen();
  },
  // Legacy checkout/payment deep links are intentionally routed back to cart.
  // The production flow creates an order conversation with NovaShop instead.
  RouteNames.checkout: (_) => const CartScreen(),
  RouteNames.payment: (_) => const CartScreen(),
  RouteNames.paymentMethods: (_) => const CartScreen(),
  RouteNames.orderConfirmation: (args) {
    if (args is OrderConfirmationArgs) {
      return OrderConfirmationScreen(
        orderNumber: args.orderNumber,
        total: args.total,
        itemCount: args.itemCount,
      );
    }
    return const CartScreen();
  },
});

class OrderConfirmationArgs {
  const OrderConfirmationArgs({
    required this.orderNumber,
    required this.total,
    required this.itemCount,
  });

  final String orderNumber;
  final double total;
  final int itemCount;
}
