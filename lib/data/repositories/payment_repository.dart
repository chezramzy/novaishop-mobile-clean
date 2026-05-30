import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/api_collection.dart';
import '../models/payment_record.dart';
import 'repository_error.dart';

class PaymentRepository {
  PaymentRepository({required String? accessToken})
      : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession(String message) {
    if (!_hasSession) throw RepositoryException(message);
  }

  Future<ApiCollection<PaymentRecord>> getPayments({
    int page = 1,
    int pageSize = 20,
  }) async {
    _requireSession('Reconnectez-vous pour voir vos paiements.');
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final rows = await Supabase.instance.client
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);
      final items = rows
          .whereType<Map>()
          .map((row) => PaymentRecord.fromJson(_paymentJson(row)))
          .toList();
      return ApiCollection(
        items: items,
        total: items.length,
        page: page,
        pageSize: pageSize,
        totalPages: items.isEmpty ? 0 : page,
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<PaymentRecord> createIntent(String orderId) async {
    throw RepositoryException(
      'La creation d\'intention de paiement doit passer par le backend '
      'securise. Aucun paiement local ne sera cree.',
    );
  }

  Future<PaymentRecord> confirmPayment(
    String paymentId, {
    bool simulateFailure = false,
  }) async {
    throw RepositoryException(
      'La confirmation de paiement doit etre validee par le prestataire. '
      'Aucun succes local ne sera simule.',
    );
  }

  Future<PaymentRecord> refundPayment(
    String paymentId, {
    required String reason,
  }) async {
    throw RepositoryException(
      'Le remboursement doit passer par le backend de paiement. '
      'Aucun remboursement local ne sera simule.',
    );
  }

  Map<String, dynamic> _paymentJson(Map row) {
    final json = Map<String, dynamic>.from(row);
    return {
      ...json,
      'orderId': json['order_id'],
      'commissionAmount': json['commission_amount'],
      'vendorAllocation': json['vendor_allocation'],
      'payoutAccountId': json['payout_account_id'],
      'createdAt': json['created_at'],
    };
  }
}
