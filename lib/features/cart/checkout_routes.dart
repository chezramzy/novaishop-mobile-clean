import '../../app/router/app_router.dart';
import '../../app/router/route_names.dart';
import '../checkout/checkout_flow.dart';
import '../checkout/checkout_screen.dart';
import '../checkout/order_confirmation_screen.dart';
import '../checkout/payment_screen.dart';
import '../messages/order_conversation_screen.dart';
import '../payment/payment_methods_screen.dart';
import 'cart_screen.dart';

/// Routes contributed by WS3 (panier, checkout, paiement).
final FeatureRoutes checkoutRoutes = FeatureRoutes(<String, RouteArgsBuilder>{
  RouteNames.cart: (_) => const CartScreen(),
  RouteNames.orderConversation: (args) {
    if (args is OrderConversationArgs) {
      return OrderConversationScreen(conversation: args.conversation);
    }
    return const CartScreen();
  },
  RouteNames.checkout: (_) => const CheckoutScreen(),
  RouteNames.payment: (args) {
    if (args is CheckoutDraft) return PaymentScreen(draft: args);
    // Reached without a draft (deep link / refresh) — fall back to checkout.
    return const CheckoutScreen();
  },
  RouteNames.paymentMethods: (_) => const PaymentMethodsScreen(),
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

/// Arguments accepted by the [RouteNames.orderConfirmation] route when it is
/// reached by name rather than via the in-flow `pushReplacement`.
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
