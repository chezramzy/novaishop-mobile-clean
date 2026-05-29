import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/api_collection.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../models/payment_record.dart';
import '../models/seller_analytics.dart';
import '../models/seller_dashboard.dart';
import '../models/seller_workspace.dart';
import '../models/shop.dart';
import '../models/vendor_profile.dart';
import 'repository_error.dart';

class SellerException implements Exception {
  SellerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SellerRepository {
  SellerRepository({required String? accessToken})
      : _hasToken = accessToken != null &&
            accessToken.isNotEmpty &&
            !accessToken.startsWith('local:');

  final bool _hasToken;

  void _requireToken() {
    if (!_hasToken || Supabase.instance.client.auth.currentUser == null) {
      throw SellerException(
        'Reconnectez-vous avec votre compte NovaShop pour gerer vos produits.',
      );
    }
  }

  Future<SellerWorkspace?> loadWorkspace() async {
    final dashboard = await getDashboard();
    if (dashboard == null) return null;
    return SellerWorkspace(
      vendorId: dashboard.vendor.id,
      shopId: dashboard.vendor.shopId,
      shopName: 'Catalogue partenaire',
      kycStatus: dashboard.vendor.kycStatus,
      listings: dashboard.listings,
      activeOrdersCount: dashboard.activeOrders.length,
      pendingModerationCount: dashboard.pendingListings,
    );
  }

  Future<SellerDashboardSummary?> getDashboard() async {
    _requireToken();
    try {
      final vendor = await _myVendor();
      if (vendor == null) return null;
      final shop = await _shop(vendor.shopId);
      final listings = await _partnerListings();
      return SellerDashboardSummary(
        vendor: vendor,
        shop: shop,
        listings: listings,
        activeOrders: const [],
        pendingPayouts: const <PaymentRecord>[],
        moderationQueue: const <ModerationCase>[],
        kycDocuments: const <KycDocument>[],
      );
    } catch (error) {
      if (error is SellerException) rethrow;
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<SellerDashboardSummary?> ensureApprovedPartnerDashboard() {
    return getDashboard();
  }

  Future<VendorProfile?> getMyVendorProfile() {
    _requireToken();
    return _myVendor();
  }

  Future<SellerAnalytics> getAnalytics() async {
    final dashboard = await getDashboard();
    final listings = dashboard?.listings ?? const <Listing>[];
    return SellerAnalytics(
      revenueTimeSeries: const [],
      bestSellers: const [],
      stockLevels: [
        for (final listing in listings)
          StockLevelStat(
            listingId: listing.id,
            title: listing.title,
            inventory: listing.inventory,
            status: listing.inventory == 0
                ? 'out'
                : listing.inventory <= 5
                    ? 'low'
                    : 'ok',
          ),
      ],
      orderStatusDistribution: const [],
      totalRevenue: 0,
      totalOrders: 0,
      averageOrderValue: 0,
    );
  }

  Future<void> createShop({
    required String shopName,
    required String shopDescription,
    required String sellerType,
    required String legalFullName,
    required String supportEmail,
    required String contactPhone,
    required String country,
    required String city,
    required String addressLine,
    required String customerPromise,
    String shopTagline = '',
    String businessName = '',
  }) async {
    throw SellerException(
      'L espace partenaire est cree automatiquement apres approbation admin.',
    );
  }

  Future<void> submitOnboarding({
    required String shopName,
    required String shopDescription,
    required String sellerType,
    required String legalFullName,
    required String supportEmail,
    required String contactPhone,
    required String country,
    required String city,
    required String addressLine,
    required String customerPromise,
    List<String> focus = const ['product'],
    String catalogSize = 'starter',
    String inventoryMode = 'owned_stock',
    String launchTimeline = 'immediate',
    List<String>? fulfillmentRegions,
    String shopTagline = '',
    String businessName = '',
    String supportPhone = '',
  }) {
    return createShop(
      shopName: shopName,
      shopDescription: shopDescription,
      sellerType: sellerType,
      legalFullName: legalFullName,
      supportEmail: supportEmail,
      contactPhone: contactPhone,
      country: country,
      city: city,
      addressLine: addressLine,
      customerPromise: customerPromise,
      shopTagline: shopTagline,
      businessName: businessName,
    );
  }

  Future<Listing> createListing({
    required String shopId,
    required String categoryId,
    required String title,
    required String description,
    required double price,
    required int inventory,
    String categoryType = 'product',
    String currency = 'XOF',
    String imageUrl = '',
    Map<String, dynamic>? attributes,
  }) async {
    _requireToken();
    try {
      final vendor = await _myVendor();
      if (vendor == null || !vendor.isApproved) {
        throw SellerException(
          'Votre demande partenaire doit etre approuvee avant ajout produit.',
        );
      }
      final userId = _userId;
      final now = DateTime.now().millisecondsSinceEpoch;
      final rows = await Supabase.instance.client
          .from('listings')
          .insert({
            'vendor_id': vendor.id,
            'shop_id': vendor.shopId,
            'category_id': categoryId,
            'category_type': categoryType,
            'slug': _slug('$title-$now'),
            'title': title.trim(),
            'description': description.trim(),
            'status': 'pending_review',
            'price': price,
            'currency': currency,
            'inventory': inventory,
            'featured': false,
            'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
            'attributes': {
              ...?attributes,
              'partnerUserId': userId,
              'submittedFrom': 'mobile_app',
            },
            'partner_user_id': userId,
          })
          .select()
          .limit(1);
      return Listing.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } on SellerException {
      rethrow;
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Listing> updateListing(
    String listingId, {
    String? title,
    String? description,
    double? price,
    String? currency,
    int? inventory,
    String? imageUrl,
    Map<String, dynamic>? attributes,
  }) async {
    _requireToken();
    final body = <String, dynamic>{'status': 'pending_review'};
    if (title != null) body['title'] = title.trim();
    if (description != null) body['description'] = description.trim();
    if (price != null) body['price'] = price;
    if (currency != null) body['currency'] = currency;
    if (inventory != null) body['inventory'] = inventory;
    if (imageUrl != null) {
      body['image_url'] = imageUrl.trim().isEmpty ? null : imageUrl.trim();
    }
    if (attributes != null) {
      body['attributes'] = {
        ...attributes,
        'partnerUserId': _userId,
        'submittedFrom': 'mobile_app',
      };
    }
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .update(body)
          .eq('id', listingId)
          .select()
          .limit(1);
      return Listing.fromJson(Map<String, dynamic>.from(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<ApiCollection<Order>> getVendorOrders(
    String vendorId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _requireToken();
    return ApiCollection(
      items: const [],
      total: 0,
      page: page,
      pageSize: pageSize,
      totalPages: 0,
    );
  }

  Future<Order> updateOrderStatus(
    String vendorId,
    String orderId, {
    required String status,
    String? trackingNumber,
  }) async {
    _requireToken();
    throw SellerException(
        'La gestion des commandes partenaire arrive ensuite.');
  }

  Future<VendorProfile?> _myVendor() async {
    final rows = await Supabase.instance.client
        .from('vendors')
        .select()
        .eq('user_id', _userId)
        .limit(1);
    if (rows.isEmpty) return null;
    return _vendorFromRow(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<Shop> _shop(String shopId) async {
    final rows = await Supabase.instance.client
        .from('shops')
        .select()
        .eq('id', shopId)
        .limit(1);
    if (rows.isEmpty) {
      return Shop(
        id: shopId,
        vendorId: '',
        name: 'Catalogue partenaire',
        slug: '',
        description: '',
        focus: const ['product'],
        createdAt: '',
      );
    }
    final row = Map<String, dynamic>.from(rows.first as Map);
    return Shop(
      id: '${row['id'] ?? ''}',
      vendorId: '${row['vendor_id'] ?? ''}',
      name: 'Catalogue partenaire',
      slug: '${row['slug'] ?? ''}',
      description: '${row['description'] ?? ''}',
      focus: const ['product'],
      createdAt: '${row['created_at'] ?? ''}',
    );
  }

  Future<List<Listing>> _partnerListings() async {
    final rows = await Supabase.instance.client
        .from('listings')
        .select()
        .eq('partner_user_id', _userId)
        .order('created_at', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => Listing.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  VendorProfile _vendorFromRow(Map<String, dynamic> row) {
    return VendorProfile(
      id: '${row['id'] ?? ''}',
      userId: '${row['user_id'] ?? ''}',
      shopId: '${row['shop_id'] ?? ''}',
      kycStatus: '${row['kyc_status'] ?? 'draft'}',
      payoutAccountStatus: '${row['payout_account_status'] ?? 'pending'}',
      commissionRate: (row['commission_rate'] as num?)?.toDouble() ?? 0,
      documentsComplete: row['documents_complete'] == true,
      sellerType: row['seller_type'] as String?,
      legalFullName: row['legal_name'] as String?,
      createdAt: '${row['created_at'] ?? ''}',
    );
  }

  String get _userId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw SellerException('Session introuvable. Reconnectez-vous.');
    }
    return id;
  }

  String _slug(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty
        ? 'produit-${DateTime.now().millisecondsSinceEpoch}'
        : normalized;
  }
}
