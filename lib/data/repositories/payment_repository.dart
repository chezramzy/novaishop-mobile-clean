import '../models/api_collection.dart';
import '../models/payment_record.dart';

class PaymentRepository {
  PaymentRepository({required String? accessToken});

  Future<ApiCollection<PaymentRecord>> getPayments({
    int page = 1,
    int pageSize = 20,
  }) async {
    return ApiCollection(
      items: const [],
      total: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
    );
  }

  Future<PaymentRecord> createIntent(String orderId) async {
    return PaymentRecord.fromJson({
      'id': 'payment-${DateTime.now().microsecondsSinceEpoch}',
      'orderId': orderId,
      'provider': 'local',
      'status': 'requires_confirmation',
      'amount': 0,
      'currency': 'XOF',
      'commissionAmount': 0,
      'vendorAllocation': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<PaymentRecord> confirmPayment(
    String paymentId, {
    bool simulateFailure = false,
  }) async {
    return PaymentRecord.fromJson({
      'id': paymentId,
      'orderId': '',
      'provider': 'local',
      'status': simulateFailure ? 'failed' : 'succeeded',
      'amount': 0,
      'currency': 'XOF',
      'commissionAmount': 0,
      'vendorAllocation': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<PaymentRecord> refundPayment(
    String paymentId, {
    required String reason,
  }) async {
    return PaymentRecord.fromJson({
      'id': paymentId,
      'orderId': '',
      'provider': 'local',
      'status': 'refunded',
      'amount': 0,
      'currency': 'XOF',
      'commissionAmount': 0,
      'vendorAllocation': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
