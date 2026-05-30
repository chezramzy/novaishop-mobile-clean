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
      final orders = await getVendorOrders(vendor.id, pageSize: 10);
      return SellerDashboardSummary(
        vendor: vendor,
        shop: shop,
        listings: listings,
        activeOrders: orders.items
            .where((order) =>
                !{'delivered', 'cancelled', 'refunded'}.contains(order.status))
            .toList(growable: false),
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
    final orders = dashboard?.activeOrders ?? const <Order>[];
    final revenue = orders.fold<double>(0, (sum, order) => sum + order.total);
    final statusCounts = <String, int>{};
    for (final order in orders) {
      statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
    }
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
      orderStatusDistribution: [
        for (final entry in statusCounts.entries)
          StatusCount(status: entry.key, count: entry.value),
      ],
      totalRevenue: revenue,
      totalOrders: orders.length,
      averageOrderValue: orders.isEmpty ? 0 : revenue / orders.length,
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
      final cleanAttributes = Map<String, dynamic>.from(attributes ?? {});
      final rawVariants =
          cleanAttributes['variants'] ?? cleanAttributes['productVariants'];
      final variants = rawVariants is List ? rawVariants : const [];
      final rawImages =
          cleanAttributes['listingImages'] ?? cleanAttributes['images'];
      final images = rawImages is List
          ? rawImages
          : imageUrl.trim().isEmpty
              ? const []
              : [
                  {
                    'url': imageUrl.trim(),
                    'isPrimary': true,
                    'sortOrder': 0,
                  }
                ];
      final row = await Supabase.instance.client.rpc(
        'submit_partner_listing',
        params: {
          'p_category_id': categoryId,
          'p_title': title.trim(),
          'p_description': description.trim(),
          'p_price': price,
          'p_inventory': inventory,
          'p_category_type': categoryType,
          'p_currency': currency,
          'p_image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'p_attributes': cleanAttributes,
          'p_variants': variants,
          'p_images': images,
        },
      );
      return Listing.fromJson(Map<String, dynamic>.from(row as Map));
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
    try {
      await _assertVendorAccess(vendorId);
      final from = (page - 1) * pageSize;
      final to = from + pageSize - 1;
      final groups = await Supabase.instance.client
          .from('seller_order_groups')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false)
          .range(from, to);
      final orders = <Order>[];
      for (final group in groups.whereType<Map>()) {
        final order = await _vendorOrderFromGroup(
          vendorId,
          Map<String, dynamic>.from(group),
        );
        if (order != null) orders.add(order);
      }
      return ApiCollection(
        items: orders,
        total: orders.length,
        page: page,
        pageSize: pageSize,
        totalPages: orders.isEmpty ? 0 : page,
      );
    } catch (error) {
      if (error is SellerException) rethrow;
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Order> updateOrderStatus(
    String vendorId,
    String orderId, {
    required String status,
    String? trackingNumber,
  }) async {
    _requireToken();
    try {
      await _assertVendorAccess(vendorId);
      await Supabase.instance.client.rpc(
        'update_partner_order_status',
        params: {
          'p_vendor_id': vendorId,
          'p_order_id': orderId,
          'p_status': status,
          'p_tracking_number': trackingNumber,
        },
      );
      final groups = await Supabase.instance.client
          .from('seller_order_groups')
          .select()
          .eq('vendor_id', vendorId)
          .eq('order_id', orderId)
          .limit(1);
      if (groups.isEmpty) {
        throw SellerException('Commande partenaire introuvable.');
      }
      final order = await _vendorOrderFromGroup(
        vendorId,
        Map<String, dynamic>.from(groups.first as Map),
        trackingNumber: trackingNumber,
      );
      if (order == null) {
        throw SellerException('Commande partenaire introuvable.');
      }
      return order;
    } catch (error) {
      if (error is SellerException) rethrow;
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<void> _assertVendorAccess(String vendorId) async {
    final vendor = await _myVendor();
    if (vendor == null || vendor.id != vendorId) {
      throw SellerException('Acces partenaire non autorise.');
    }
  }

  Future<Order?> _vendorOrderFromGroup(
    String vendorId,
    Map<String, dynamic> group, {
    String? trackingNumber,
  }) async {
    final orderId = '${group['order_id'] ?? ''}';
    if (orderId.isEmpty) return null;
    final orderRows = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('id', orderId)
        .limit(1);
    if (orderRows.isEmpty) return null;
    final itemRows = await Supabase.instance.client
        .from('order_items')
        .select()
        .eq('order_id', orderId)
        .eq('vendor_id', vendorId)
        .order('id');
    final order = Map<String, dynamic>.from(orderRows.first as Map);
    final subtotal = (group['subtotal'] as num?)?.toDouble() ??
        itemRows.whereType<Map>().fold<double>(
              0,
              (sum, item) => sum + ((item['total_price'] as num?) ?? 0),
            );
    final commission = (group['commission_amount'] as num?)?.toDouble() ?? 0;
    return Order.fromJson({
      ...order,
      'status': group['status'] ?? order['status'],
      'customerId': order['customer_id'],
      'sellerOrderIds': ['${group['id'] ?? ''}'],
      'subtotal': subtotal,
      'commissionTotal': commission,
      'total': subtotal,
      'createdAt': order['created_at'] ?? group['created_at'],
      'trackingNumber': trackingNumber,
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
}
