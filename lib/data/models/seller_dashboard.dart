import 'json_utils.dart';
import 'listing.dart';
import 'order.dart';
import 'payment_record.dart';
import 'shop.dart';
import 'vendor_profile.dart';

/// A moderation case raised against a vendor or listing.
class ModerationCase {
  const ModerationCase({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  final String id;

  /// `vendor` or `listing`.
  final String entityType;
  final String entityId;

  /// `open`, `approved` or `rejected`.
  final String status;
  final String reason;
  final String createdAt;

  factory ModerationCase.fromJson(Map<String, dynamic> json) {
    return ModerationCase(
      id: Json.str(json['id']),
      entityType: Json.str(json['entityType']),
      entityId: Json.str(json['entityId']),
      status: Json.str(json['status'], 'open'),
      reason: Json.str(json['reason']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

/// A KYC document submitted by a seller.
class KycDocument {
  const KycDocument({
    required this.id,
    required this.vendorId,
    required this.mediaId,
    required this.documentType,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String id;
  final String vendorId;
  final String mediaId;

  /// `identity`, `business` or `address`.
  final String documentType;

  /// `pending_review`, `approved` or `rejected`.
  final String status;
  final String? rejectionReason;
  final String createdAt;
  final String? reviewedAt;

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: Json.str(json['id']),
      vendorId: Json.str(json['vendorId']),
      mediaId: Json.str(json['mediaId']),
      documentType: Json.str(json['documentType']),
      status: Json.str(json['status'], 'pending_review'),
      rejectionReason: Json.strOrNull(json['rejectionReason']),
      createdAt: Json.str(json['createdAt']),
      reviewedAt: Json.strOrNull(json['reviewedAt']),
    );
  }
}

/// The full seller dashboard snapshot (`SellerDashboardSummary` interface),
/// returned by `GET /v1/vendors/me/dashboard`.
class SellerDashboardSummary {
  const SellerDashboardSummary({
    required this.vendor,
    required this.shop,
    required this.listings,
    required this.activeOrders,
    required this.pendingPayouts,
    required this.moderationQueue,
    required this.kycDocuments,
  });

  final VendorProfile vendor;
  final Shop shop;
  final List<Listing> listings;
  final List<Order> activeOrders;
  final List<PaymentRecord> pendingPayouts;
  final List<ModerationCase> moderationQueue;
  final List<KycDocument> kycDocuments;

  int get totalListings => listings.length;

  int get publishedListings =>
      listings.where((listing) => listing.status == 'published').length;

  int get pendingListings => listings
      .where((listing) =>
          listing.status == 'pending_review' || listing.status == 'draft')
      .length;

  factory SellerDashboardSummary.fromJson(Map<String, dynamic> json) {
    return SellerDashboardSummary(
      vendor: VendorProfile.fromJson(Json.obj(json['vendor'])),
      shop: Shop.fromJson(Json.obj(json['shop'])),
      listings: Json.list(json['listings'], Listing.fromJson),
      activeOrders: Json.list(json['activeOrders'], Order.fromJson),
      pendingPayouts: Json.list(json['pendingPayouts'], PaymentRecord.fromJson),
      moderationQueue:
          Json.list(json['moderationQueue'], ModerationCase.fromJson),
      kycDocuments: Json.list(json['kycDocuments'], KycDocument.fromJson),
    );
  }
}
