import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/api_collection.dart';
import '../models/order.dart';
import 'repository_error.dart';

class OrderRepository {
  OrderRepository({String? accessToken}) : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentUser != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession() {
    if (!_hasSession) {
      throw RepositoryException('Reconnectez-vous pour voir vos commandes.');
    }
  }

  Future<ApiCollection<Order>> getOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    _requireSession();
    try {
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('customer_id', _userId)
          .order('created_at', ascending: false)
          .range(from, to);
      final items = <Order>[];
      for (final row in rows.whereType<Map>()) {
        items.add(await _orderFromRow(Map<String, dynamic>.from(row)));
      }
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

  Future<Order?> getOrder(String orderId) async {
    _requireSession();
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', orderId)
          .eq('customer_id', _userId)
          .limit(1);
      if (rows.isEmpty) return null;
      return _orderFromRow(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Order> createOrder(List<({String listingId, int quantity})> items) {
    throw RepositoryException(
      'Les commandes sont creees via la conversation NovaShop.',
    );
  }

  Future<Order> _orderFromRow(Map<String, dynamic> row) async {
    final itemRows = await Supabase.instance.client
        .from('order_items')
        .select()
        .eq('order_id', row['id'])
        .order('id');
    final groupRows = await Supabase.instance.client
        .from('seller_order_groups')
        .select('id')
        .eq('order_id', row['id']);
    return Order.fromJson({
      ...row,
      'customerId': row['customer_id'],
      'sellerOrderIds': [
        for (final group in groupRows.whereType<Map>()) '${group['id']}',
      ],
      'commissionTotal': row['commission_total'],
      'createdAt': row['created_at'],
      'items': [
        for (final item in itemRows.whereType<Map>())
          {
            ...Map<String, dynamic>.from(item),
            'listingId': item['listing_id'],
            'vendorId': item['vendor_id'],
            'unitPrice': item['unit_price'],
            'totalPrice': item['total_price'],
          }
      ],
    });
  }

  String get _userId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    return id;
  }
}
