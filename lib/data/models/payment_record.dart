import 'json_utils.dart';

/// A payment record for an order (`PaymentRecord` interface).
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.status,
    required this.amount,
    required this.currency,
    required this.commissionAmount,
    required this.vendorAllocation,
    required this.createdAt,
    this.payoutAccountId,
  });

  final String id;
  final String orderId;

  /// One of the configured payment providers.
  final String provider;

  /// One of: `requires_payment_method`, `requires_confirmation`,
  /// `processing`, `succeeded`, `failed`, `refunded`.
  final String status;
  final double amount;
  final String currency;
  final double commissionAmount;
  final double vendorAllocation;
  final String? payoutAccountId;
  final String createdAt;

  bool get isSucceeded => status == 'succeeded';
  bool get isFailed => status == 'failed';
  bool get needsConfirmation => status == 'requires_confirmation';

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: Json.str(json['id']),
      orderId: Json.str(json['orderId']),
      provider: Json.str(json['provider'], 'unconfigured'),
      status: Json.str(json['status'], 'requires_confirmation'),
      amount: Json.dbl(json['amount']),
      currency: Json.str(json['currency'], 'XOF'),
      commissionAmount: Json.dbl(json['commissionAmount']),
      vendorAllocation: Json.dbl(json['vendorAllocation']),
      payoutAccountId: Json.strOrNull(json['payoutAccountId']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
