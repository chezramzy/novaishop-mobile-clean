import 'listing.dart';

/// Snapshot of a partner workspace.
class SellerWorkspace {
  const SellerWorkspace({
    required this.vendorId,
    required this.shopId,
    required this.shopName,
    required this.kycStatus,
    required this.listings,
    required this.activeOrdersCount,
    required this.pendingModerationCount,
    this.shopTagline,
    this.shopCity,
  });

  final String vendorId;
  final String shopId;
  final String shopName;
  final String? shopTagline;
  final String? shopCity;

  /// One of: submitted, in_review, approved, rejected.
  final String kycStatus;
  final List<Listing> listings;
  final int activeOrdersCount;
  final int pendingModerationCount;

  int get totalProducts => listings.length;

  int get publishedProducts =>
      listings.where((listing) => listing.status == 'published').length;

  int get pendingProducts => listings
      .where((listing) =>
          listing.status == 'pending_review' || listing.status == 'draft')
      .length;

  bool get isShopApproved => kycStatus == 'approved';

  factory SellerWorkspace.fromDashboardJson(Map<String, dynamic> json) {
    final vendor =
        Map<String, dynamic>.from(json['vendor'] as Map? ?? const {});
    final shop = Map<String, dynamic>.from(json['shop'] as Map? ?? const {});
    final rawListings = json['listings'];
    final rawOrders = json['activeOrders'];
    final rawModeration = json['moderationQueue'];

    return SellerWorkspace(
      vendorId: vendor['id'] as String? ?? '',
      shopId: shop['id'] as String? ?? vendor['shopId'] as String? ?? '',
      shopName: shop['name'] as String? ?? 'Catalogue partenaire',
      shopTagline: shop['tagline'] as String?,
      shopCity: shop['city'] as String?,
      kycStatus: vendor['kycStatus'] as String? ?? 'submitted',
      listings: rawListings is List
          ? rawListings
              .whereType<Map>()
              .map((item) => Listing.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      activeOrdersCount: rawOrders is List ? rawOrders.length : 0,
      pendingModerationCount: rawModeration is List ? rawModeration.length : 0,
    );
  }
}

/// Human-readable French status for a listing returned by the API.
String listingStatusLabel(String status) {
  switch (status) {
    case 'published':
      return 'En ligne';
    case 'pending_review':
      return 'En validation';
    case 'draft':
      return 'Brouillon';
    case 'rejected':
      return 'Refusé';
    case 'archived':
      return 'Archivé';
    default:
      return status;
  }
}
