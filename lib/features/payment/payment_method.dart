import 'package:flutter/material.dart';

import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';

/// The supported brands once a real payment provider is connected.
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

/// A payment method shape kept for future real provider integration.
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

class PaymentMethodStore {
  PaymentMethodStore._();

  static final PaymentMethodStore instance = PaymentMethodStore._();

  Never _unsupported() {
    throw RepositoryException(
      'Les moyens de paiement doivent etre geres par un backend de paiement securise.',
    );
  }

  Future<List<PaymentMethod>> getMethods() async => _unsupported();

  /// The current default method, or `null` when none are saved.
  Future<PaymentMethod?> getDefault() async => _unsupported();

  /// Adds [method]. The first method added becomes the default.
  Future<List<PaymentMethod>> add(PaymentMethod method) async => _unsupported();

  /// Removes the method with [id]. Promotes the first remaining to default.
  Future<List<PaymentMethod>> remove(String id) async => _unsupported();

  /// Marks the method with [id] as the default.
  Future<List<PaymentMethod>> setDefault(String id) async => _unsupported();
}
