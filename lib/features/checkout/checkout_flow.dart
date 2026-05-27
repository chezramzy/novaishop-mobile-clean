import '../../data/models/address.dart';
import '../../data/models/coupon.dart';

/// Flat per-order shipping fee applied at checkout (mock — there is no
/// shipping API). Free above a generous threshold.
const double kCheckoutShippingFee = 4.99;
const double kCheckoutFreeShippingThreshold = 80;

/// Immutable snapshot of everything chosen during checkout. Passed from the
/// checkout screen to the payment screen and on to the confirmation screen.
class CheckoutDraft {
  const CheckoutDraft({
    required this.address,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.couponCode,
    required this.items,
  });

  /// The selected delivery address.
  final Address address;

  /// Sum of the cart line items.
  final double subtotal;

  /// Delivery fee (0 when free shipping applies).
  final double shippingFee;

  /// Coupon discount amount (0 when no valid coupon).
  final double discount;

  /// The applied coupon code, if any.
  final String? couponCode;

  /// The (listingId, quantity) pairs to send to the orders API.
  final List<({String listingId, int quantity})> items;

  double get total {
    final value = subtotal + shippingFee - discount;
    return value < 0 ? 0 : value;
  }
}

/// Computes the shipping fee for a given subtotal.
double shippingFeeFor(double subtotal) {
  if (subtotal <= 0) return 0;
  return subtotal >= kCheckoutFreeShippingThreshold ? 0 : kCheckoutShippingFee;
}

/// Computes a coupon discount from a validation result, clamped so it never
/// exceeds the order subtotal.
double discountFromCoupon(CouponValidationResult result, double subtotal) {
  if (!result.valid) return 0;
  final amount = result.discountAmount ?? 0;
  if (amount <= 0) return 0;
  return amount > subtotal ? subtotal : amount;
}
