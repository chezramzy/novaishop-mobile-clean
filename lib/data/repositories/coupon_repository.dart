import '../models/coupon.dart';
import 'repository_error.dart';

class CouponRepository {
  CouponRepository({required String? accessToken});

  final _coupons = <Coupon>[];

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required double orderAmount,
  }) async {
    return const CouponValidationResult(
      valid: false,
      message: 'Coupon indisponible en mode local.',
    );
  }

  Future<List<Coupon>> getCoupons() async => List.unmodifiable(_coupons);

  Future<Coupon> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    double? minOrderAmount,
    int? maxUses,
    String? validFrom,
    String? validTo,
  }) async {
    final coupon = Coupon.fromJson({
      'id': 'coupon-${DateTime.now().microsecondsSinceEpoch}',
      'code': code.trim().toUpperCase(),
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount ?? 0,
      'maxUses': maxUses ?? 0,
      'usedCount': 0,
      'validFrom': validFrom ?? '',
      'validTo': validTo ?? '',
      'active': true,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    _coupons.add(coupon);
    return coupon;
  }

  Future<Coupon> deactivateCoupon(String couponId) async {
    throw RepositoryException('Coupon local introuvable.');
  }
}
