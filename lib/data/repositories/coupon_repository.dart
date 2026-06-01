import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/coupon.dart';
import 'repository_error.dart';

class CouponRepository {
  CouponRepository({required String? accessToken}) : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession(String message) {
    if (!_hasSession) throw RepositoryException(message);
  }

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required double orderAmount,
  }) async {
    _requireSession('Reconnectez-vous pour utiliser un coupon.');
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const CouponValidationResult(
        valid: false,
        message: 'Saisissez un code coupon.',
      );
    }
    try {
      final rows = await Supabase.instance.client.rpc(
        'validate_coupon_code',
        params: {
          'p_code': normalized,
          'p_order_amount': orderAmount,
        },
      ) as List<dynamic>;
      if (rows.isEmpty) {
        return const CouponValidationResult(
          valid: false,
          message: 'Coupon introuvable, inactif ou non applicable.',
        );
      }

      final coupon = Coupon.fromJson(_couponJson(rows.first as Map));
      final discount = coupon.isPercentage
          ? orderAmount * (coupon.discountValue / 100)
          : coupon.discountValue;
      return CouponValidationResult(
        valid: true,
        coupon: coupon,
        discountAmount: discount.clamp(0, orderAmount).toDouble(),
        message: 'Coupon applique.',
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Coupon>> getCoupons() async {
    _requireSession('Reconnectez-vous pour voir vos coupons.');
    try {
      final vendorId = await _currentVendorId();
      final rows = await Supabase.instance.client
          .from('coupons')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => Coupon.fromJson(_couponJson(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Coupon> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    double? minOrderAmount,
    int? maxUses,
    String? validFrom,
    String? validTo,
  }) async {
    _requireSession('Reconnectez-vous pour creer un coupon.');
    try {
      final vendorId = await _currentVendorId();
      final rows = await Supabase.instance.client
          .from('coupons')
          .insert({
            'code': code.trim().toUpperCase(),
            'discount_type': discountType,
            'discount_value': discountValue,
            'min_order_amount': minOrderAmount ?? 0,
            'max_uses': maxUses ?? 0,
            if (validFrom != null && validFrom.isNotEmpty)
              'valid_from': validFrom,
            if (validTo != null && validTo.isNotEmpty) 'valid_to': validTo,
            'vendor_id': vendorId,
            'active': true,
          })
          .select()
          .limit(1);
      return Coupon.fromJson(_couponJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Coupon> deactivateCoupon(String couponId) async {
    _requireSession('Reconnectez-vous pour modifier ce coupon.');
    try {
      final vendorId = await _currentVendorId();
      final rows = await Supabase.instance.client
          .from('coupons')
          .update({'active': false})
          .eq('id', couponId)
          .eq('vendor_id', vendorId)
          .select()
          .limit(1);
      if (rows.isEmpty) {
        throw RepositoryException('Coupon introuvable ou non autorise.');
      }
      return Coupon.fromJson(_couponJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<String> _currentVendorId() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    final rows = await Supabase.instance.client
        .from('vendors')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);
    if (rows.isEmpty) {
      throw RepositoryException(
        'Profil partenaire introuvable. Impossible de gerer les coupons.',
      );
    }
    return (rows.first as Map)['id'].toString();
  }

  Map<String, dynamic> _couponJson(Map row) {
    final json = Map<String, dynamic>.from(row);
    return {
      ...json,
      'discountType': json['discount_type'],
      'discountValue': json['discount_value'],
      'minOrderAmount': json['min_order_amount'],
      'maxUses': json['max_uses'],
      'usedCount': json['used_count'],
      'validFrom': json['valid_from'],
      'validTo': json['valid_to'],
      'vendorId': json['vendor_id'],
      'createdAt': json['created_at'],
    };
  }
}
