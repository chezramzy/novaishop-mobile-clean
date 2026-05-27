import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/design_system.dart';

/// The supported brands of a saved (mock) payment method.
enum PaymentBrand { visa, mastercard, paypal, applePay, mobileMoney }

extension PaymentBrandX on PaymentBrand {
  /// The French display label.
  String get label {
    switch (this) {
      case PaymentBrand.visa:
        return 'Visa';
      case PaymentBrand.mastercard:
        return 'Mastercard';
      case PaymentBrand.paypal:
        return 'PayPal';
      case PaymentBrand.applePay:
        return 'Apple Pay';
      case PaymentBrand.mobileMoney:
        return 'Mobile Money';
    }
  }

  /// Whether the brand represents a card (vs. a wallet).
  bool get isCard =>
      this == PaymentBrand.visa || this == PaymentBrand.mastercard;

  IconData get icon {
    switch (this) {
      case PaymentBrand.visa:
      case PaymentBrand.mastercard:
        return Icons.credit_card_rounded;
      case PaymentBrand.paypal:
        return Icons.account_balance_wallet_outlined;
      case PaymentBrand.applePay:
        return Icons.phone_iphone_rounded;
      case PaymentBrand.mobileMoney:
        return Icons.smartphone_rounded;
    }
  }

  /// A soft accent tint for this brand, resolved against [colors] for the
  /// active light/dark theme.
  Color tintOf(NovaColors colors) {
    switch (this) {
      case PaymentBrand.visa:
        return colors.lavender;
      case PaymentBrand.mastercard:
        return colors.blush;
      case PaymentBrand.paypal:
        return colors.butter;
      case PaymentBrand.applePay:
        return colors.surfaceMuted;
      case PaymentBrand.mobileMoney:
        return colors.lavender;
    }
  }

  static PaymentBrand fromName(String? name) {
    return PaymentBrand.values.firstWhere(
      (brand) => brand.name == name,
      orElse: () => PaymentBrand.visa,
    );
  }
}

/// A locally stored, mock payment method. There is no payment-methods API,
/// so these live only on the device via `shared_preferences`.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.holder,
    required this.last4,
    this.isDefault = false,
  });

  final String id;
  final PaymentBrand brand;

  /// Card holder name or wallet account label.
  final String holder;

  /// The last 4 digits of the card / account reference.
  final String last4;
  final bool isDefault;

  /// A masked, human-readable reference.
  String get masked => brand.isCard ? '•••• •••• •••• $last4' : '•••• $last4';

  PaymentMethod copyWith({bool? isDefault}) {
    return PaymentMethod(
      id: id,
      brand: brand,
      holder: holder,
      last4: last4,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand.name,
        'holder': holder,
        'last4': last4,
        'isDefault': isDefault,
      };

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: (json['id'] ?? '').toString(),
      brand: PaymentBrandX.fromName(json['brand'] as String?),
      holder: (json['holder'] ?? '').toString(),
      last4: (json['last4'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
    );
  }
}

/// Local CRUD store for [PaymentMethod]s, backed by `shared_preferences`
/// under a WS3-owned key. Mirrors the shape of `AddressRepository`.
class PaymentMethodStore {
  PaymentMethodStore._();

  static final PaymentMethodStore instance = PaymentMethodStore._();

  static const _storeKey = 'novaishop.ws3.payment_methods';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// All saved methods, default first.
  Future<List<PaymentMethod>> getMethods() async {
    final store = await _store;
    final raw = store.getString(_storeKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final methods = decoded
          .whereType<Map>()
          .map(
              (item) => PaymentMethod.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      methods.sort((a, b) {
        if (a.isDefault == b.isDefault) return 0;
        return a.isDefault ? -1 : 1;
      });
      return methods;
    } catch (_) {
      return const [];
    }
  }

  /// The current default method, or `null` when none are saved.
  Future<PaymentMethod?> getDefault() async {
    final methods = await getMethods();
    if (methods.isEmpty) return null;
    return methods.firstWhere(
      (m) => m.isDefault,
      orElse: () => methods.first,
    );
  }

  /// Adds [method]. The first method added becomes the default.
  Future<List<PaymentMethod>> add(PaymentMethod method) async {
    final current = await getMethods();
    final isFirst = current.isEmpty;
    final toAdd = method.copyWith(isDefault: method.isDefault || isFirst);
    return _persist([...current, toAdd], toAdd.isDefault ? toAdd.id : null);
  }

  /// Removes the method with [id]. Promotes the first remaining to default.
  Future<List<PaymentMethod>> remove(String id) async {
    final current = await getMethods();
    final next = current.where((m) => m.id != id).toList();
    if (next.isNotEmpty && !next.any((m) => m.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    await _save(next);
    return getMethods();
  }

  /// Marks the method with [id] as the default.
  Future<List<PaymentMethod>> setDefault(String id) async {
    final current = await getMethods();
    return _persist(current, id);
  }

  Future<List<PaymentMethod>> _persist(
    List<PaymentMethod> methods,
    String? defaultId,
  ) async {
    final next =
        methods.map((m) => m.copyWith(isDefault: m.id == defaultId)).toList();
    if (defaultId == null && next.isNotEmpty && !next.any((m) => m.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    await _save(next);
    return getMethods();
  }

  Future<void> _save(List<PaymentMethod> methods) async {
    final store = await _store;
    await store.setString(
      _storeKey,
      jsonEncode([for (final m in methods) m.toJson()]),
    );
  }
}
