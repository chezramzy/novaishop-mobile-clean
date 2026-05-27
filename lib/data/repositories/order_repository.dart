import '../models/api_collection.dart';
import '../models/order.dart';

class OrderRepository {
  OrderRepository({String? accessToken});

  Future<ApiCollection<Order>> getOrders({
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

  Future<Order?> getOrder(String orderId) async => null;

  Future<Order> createOrder(List<({String listingId, int quantity})> items) {
    throw UnimplementedError('Les commandes locales seront branchees ensuite.');
  }
}
