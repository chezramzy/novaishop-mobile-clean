import 'json_utils.dart';

/// A product review (`Review` interface).
class Review {
  const Review({
    required this.id,
    required this.listingId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String listingId;
  final String customerId;
  final String customerName;

  /// Rating from 1 to 5.
  final int rating;
  final String comment;
  final String createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: Json.str(json['id']),
      listingId: Json.str(json['listingId']),
      customerId: Json.str(json['customerId']),
      customerName: Json.str(json['customerName']),
      rating: Json.integer(json['rating']),
      comment: Json.str(json['comment']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

/// A review of a vendor / shop (`VendorReview` interface).
class VendorReview {
  const VendorReview({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String vendorId;
  final String customerId;
  final String customerName;

  /// Rating from 1 to 5.
  final int rating;
  final String comment;
  final String? orderId;
  final String createdAt;

  factory VendorReview.fromJson(Map<String, dynamic> json) {
    return VendorReview(
      id: Json.str(json['id']),
      vendorId: Json.str(json['vendorId']),
      customerId: Json.str(json['customerId']),
      customerName: Json.str(json['customerName']),
      rating: Json.integer(json['rating']),
      comment: Json.str(json['comment']),
      orderId: Json.strOrNull(json['orderId']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
