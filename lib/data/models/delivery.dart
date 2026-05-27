import 'json_utils.dart';

/// A line item inside a [Delivery].
class DeliveryItem {
  const DeliveryItem({required this.title, required this.quantity});

  final String title;
  final int quantity;

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      title: Json.str(json['title']),
      quantity: Json.integer(json['quantity']),
    );
  }
}

/// A delivery job (`Delivery` interface).
class Delivery {
  const Delivery({
    required this.id,
    required this.orderId,
    required this.driverId,
    required this.status,
    required this.pickupAddress,
    required this.pickupCity,
    required this.deliveryAddress,
    required this.deliveryCity,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryFee,
    required this.driverEarning,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.notes,
    this.trackingNumber,
  });

  final String id;
  final String orderId;
  final String driverId;

  /// One of: `assigned`, `accepted`, `picked_up`, `in_transit`,
  /// `delivered`, `failed`, `cancelled`.
  final String status;
  final String pickupAddress;
  final String pickupCity;
  final String deliveryAddress;
  final String deliveryCity;
  final String customerName;
  final String customerPhone;
  final String? estimatedDeliveryTime;
  final String? actualDeliveryTime;
  final double deliveryFee;
  final double driverEarning;
  final String? notes;
  final String? trackingNumber;
  final List<DeliveryItem> items;
  final String createdAt;
  final String updatedAt;

  bool get isCompleted => status == 'delivered';
  bool get isActive =>
      status != 'delivered' && status != 'failed' && status != 'cancelled';

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: Json.str(json['id']),
      orderId: Json.str(json['orderId']),
      driverId: Json.str(json['driverId']),
      status: Json.str(json['status'], 'assigned'),
      pickupAddress: Json.str(json['pickupAddress']),
      pickupCity: Json.str(json['pickupCity']),
      deliveryAddress: Json.str(json['deliveryAddress']),
      deliveryCity: Json.str(json['deliveryCity']),
      customerName: Json.str(json['customerName']),
      customerPhone: Json.str(json['customerPhone']),
      estimatedDeliveryTime: Json.strOrNull(json['estimatedDeliveryTime']),
      actualDeliveryTime: Json.strOrNull(json['actualDeliveryTime']),
      deliveryFee: Json.dbl(json['deliveryFee']),
      driverEarning: Json.dbl(json['driverEarning']),
      notes: Json.strOrNull(json['notes']),
      trackingNumber: Json.strOrNull(json['trackingNumber']),
      items: Json.list(json['items'], DeliveryItem.fromJson),
      createdAt: Json.str(json['createdAt']),
      updatedAt: Json.str(json['updatedAt']),
    );
  }
}
