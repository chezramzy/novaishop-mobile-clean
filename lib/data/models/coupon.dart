import 'json_utils.dart';

/// A discount coupon (`Coupon` interface).
class Coupon {
  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxUses,
    required this.usedCount,
    required this.validFrom,
    required this.validTo,
    required this.active,
    required this.createdAt,
    this.vendorId,
  });

  final String id;
  final String code;

  /// `percentage` or `fixed`.
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final int maxUses;
  final int usedCount;
  final String validFrom;
  final String validTo;
  final String? vendorId;
  final bool active;
  final String createdAt;

  bool get isPercentage => discountType == 'percentage';

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: Json.str(json['id']),
      code: Json.str(json['code']),
      discountType: Json.str(json['discountType'], 'percentage'),
      discountValue: Json.dbl(json['discountValue']),
      minOrderAmount: Json.dbl(json['minOrderAmount']),
      maxUses: Json.integer(json['maxUses']),
      usedCount: Json.integer(json['usedCount']),
      validFrom: Json.str(json['validFrom']),
      validTo: Json.str(json['validTo']),
      vendorId: Json.strOrNull(json['vendorId']),
      active: Json.boolean(json['active'], true),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

/// The result of validating a coupon (`CouponValidationResult` interface).
class CouponValidationResult {
  const CouponValidationResult({
    required this.valid,
    required this.message,
    this.coupon,
    this.discountAmount,
  });

  final bool valid;
  final Coupon? coupon;
  final double? discountAmount;
  final String message;

  factory CouponValidationResult.fromJson(Map<String, dynamic> json) {
    final rawCoupon = json['coupon'];
    return CouponValidationResult(
      valid: Json.boolean(json['valid']),
      coupon: rawCoupon is Map
          ? Coupon.fromJson(Map<String, dynamic>.from(rawCoupon))
          : null,
      discountAmount: Json.dblOrNull(json['discountAmount']),
      message: Json.str(json['message']),
    );
  }
}
