import 'json_utils.dart';

/// A customer order spanning one or more sellers.
class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.sellerOrderIds,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.commissionTotal,
    required this.total,
    required this.items,
    required this.createdAt,
    this.trackingNumber,
  });

  final String id;
  final String customerId;
  final List<String> sellerOrderIds;

  /// One of: `pending`, `paid`, `processing`, `shipped`, `delivered`,
  /// `refunded`, `cancelled`.
  final String status;
  final String currency;
  final double subtotal;
  final double commissionTotal;
  final double total;
  final List<OrderItem> items;
  final String createdAt;
  final String? trackingNumber;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: Json.str(json['id']),
      customerId: Json.str(json['customerId']),
      sellerOrderIds: Json.stringList(json['sellerOrderIds']),
      status: Json.str(json['status'], 'pending'),
      currency: Json.str(json['currency'], 'XOF'),
      subtotal: Json.dbl(json['subtotal']),
      commissionTotal: Json.dbl(json['commissionTotal']),
      total: Json.dbl(json['total']),
      items: Json.list(json['items'], OrderItem.fromJson),
      createdAt: Json.str(json['createdAt']),
      trackingNumber: Json.strOrNull(json['trackingNumber']),
    );
  }
}

/// A single line item within an [Order].
class OrderItem {
  const OrderItem({
    required this.id,
    required this.listingId,
    required this.vendorId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  final String id;
  final String listingId;
  final String vendorId;
  final String title;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: Json.str(json['id']),
      listingId: Json.str(json['listingId']),
      vendorId: Json.str(json['vendorId']),
      title: Json.str(json['title']),
      quantity: Json.integer(json['quantity']),
      unitPrice: Json.dbl(json['unitPrice']),
      totalPrice: Json.dbl(json['totalPrice']),
    );
  }
}

/// A seller's slice of a multi-vendor order (`SellerOrderGroup`).
class SellerOrderGroup {
  const SellerOrderGroup({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.status,
    required this.subtotal,
    required this.commissionAmount,
    required this.payoutAmount,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String vendorId;
  final String status;
  final double subtotal;
  final double commissionAmount;
  final double payoutAmount;
  final String createdAt;

  factory SellerOrderGroup.fromJson(Map<String, dynamic> json) {
    return SellerOrderGroup(
      id: Json.str(json['id']),
      orderId: Json.str(json['orderId']),
      vendorId: Json.str(json['vendorId']),
      status: Json.str(json['status'], 'pending'),
      subtotal: Json.dbl(json['subtotal']),
      commissionAmount: Json.dbl(json['commissionAmount']),
      payoutAmount: Json.dbl(json['payoutAmount']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
