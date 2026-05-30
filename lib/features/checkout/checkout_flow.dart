import '../../data/models/address.dart';
import '../../data/models/coupon.dart';

/// Legacy checkout constants kept while the production flow uses order
/// conversations. They must not create local orders or payments.
const double kCheckoutShippingFee = 4.99;
const double kCheckoutFreeShippingThreshold = 80;

/// Immutable snapshot used only by legacy checkout screens that are no longer
/// exposed from the production route table.
class CheckoutDraft {
  const CheckoutDraft({
    required this.address,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.couponCode,
    required this.items,
  });

  final Address address;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final String? couponCode;
  final List<({String listingId, int quantity})> items;

  double get total {
    final value = subtotal + shippingFee - discount;
    return value < 0 ? 0 : value;
  }
}

double shippingFeeFor(double subtotal) {
  if (subtotal <= 0) return 0;
  return subtotal >= kCheckoutFreeShippingThreshold ? 0 : kCheckoutShippingFee;
}

double discountFromCoupon(CouponValidationResult result, double subtotal) {
  if (!result.valid) return 0;
  final amount = result.discountAmount ?? 0;
  if (amount <= 0) return 0;
  if (amount > subtotal) return subtotal;
  return amount;
}
