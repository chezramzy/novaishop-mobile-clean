import '../../core/api/api_exception.dart';
import '../../core/local_backend/local_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_collection.dart';
import '../models/listing.dart';
import '../models/order.dart';
import '../models/seller_analytics.dart';
import '../models/seller_dashboard.dart';
import '../models/seller_workspace.dart';
import '../models/vendor_profile.dart';
import 'repository_error.dart';

/// Raised when a seller action fails, carrying a user-facing message.
/// Retained for backward compatibility with existing seller screens.
class SellerException implements Exception {
  SellerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Authenticated access to the seller-facing API (`/v1/vendors/*` and
/// `/v1/listings`). Token-dependent — every method requires a token.
class SellerRepository {
  SellerRepository({required String? accessToken})
      : _accessToken = accessToken,
        _hasToken = accessToken != null && accessToken.isNotEmpty;

  final String? _accessToken;
  final bool _hasToken;

  void _requireToken() {
    if (!_hasToken) {
      throw SellerException(
        'Votre session a expiré. Reconnectez-vous pour gérer votre boutique.',
      );
    }
  }

  /* ------------------------------------------------------------------ */
  /*  Dashboard & profile                                               */
  /* ------------------------------------------------------------------ */

  /// Loads the seller workspace summary. Returns `null` when the seller has
  /// not created a shop yet (the API answers 404 in that case).
  Future<SellerWorkspace?> loadWorkspace() async {
    _requireToken();
    try {
      final json = await LocalBackend.instance.dashboard(_accessToken);
      if (json == null) return null;
      return SellerWorkspace.fromDashboardJson(json);
    } on LocalBackendException catch (error) {
      throw SellerException(error.message);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      throw SellerException(_friendlyError(error));
    } on SellerException {
      rethrow;
    } catch (_) {
      throw SellerException(
        'Connexion au serveur impossible. Vérifiez votre réseau.',
      );
    }
  }

  /// Loads the full seller dashboard. Returns `null` when no shop exists.
  Future<SellerDashboardSummary?> getDashboard() async {
    _requireToken();
    try {
      final json = await LocalBackend.instance.dashboard(_accessToken);
      if (json == null) return null;
      final remoteListings = await _partnerRemoteListings();
      if (remoteListings != null) {
        json['listings'] = remoteListings;
      }
      return SellerDashboardSummary.fromJson(json);
    } on LocalBackendException catch (error) {
      throw RepositoryException(error.message);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      throw RepositoryErrorMapper.wrap(error);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<SellerDashboardSummary?> ensureApprovedPartnerDashboard() async {
    _requireToken();
    try {
      await LocalBackend.instance.ensurePartnerWorkspace(
        accessToken: _accessToken,
      );
      final json = await LocalBackend.instance.dashboard(_accessToken);
      if (json == null) return null;
      final remoteListings = await _partnerRemoteListings();
      if (remoteListings != null) {
        json['listings'] = remoteListings;
      }
      return SellerDashboardSummary.fromJson(json);
    } on LocalBackendException catch (error) {
      throw RepositoryException(error.message);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// The current seller's vendor profile. Returns `null` when not a vendor.
  Future<VendorProfile?> getMyVendorProfile() async {
    _requireToken();
    try {
      final json = await LocalBackend.instance.dashboard(_accessToken);
      if (json == null) return null;
      return VendorProfile.fromJson(
        Map<String, dynamic>.from(json['vendor'] as Map),
      );
    } on LocalBackendException catch (error) {
      throw RepositoryException(error.message);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      throw RepositoryErrorMapper.wrap(error);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// The current seller's analytics.
  Future<SellerAnalytics> getAnalytics() async {
    _requireToken();
    final dashboard = await LocalBackend.instance.dashboard(_accessToken);
    final listings = dashboard == null
        ? const <Listing>[]
        : (dashboard['listings'] as List)
            .whereType<Map>()
            .map((item) => Listing.fromJson(Map<String, dynamic>.from(item)))
            .toList();
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

  /* ------------------------------------------------------------------ */
  /*  Vendor onboarding                                                  */
  /* ------------------------------------------------------------------ */

  /// Opens a shop for the current seller (vendor onboarding) — backward
  /// compatible signature used by the existing create-shop screen.
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
    await submitOnboarding(
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

  /// Submits full vendor onboarding (`POST /v1/vendors/onboarding`).
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
  }) async {
    _requireToken();
    try {
      await LocalBackend.instance.createShop(
        accessToken: _accessToken,
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
        focus: focus,
        shopTagline: shopTagline,
        businessName: businessName,
      );
    } on LocalBackendException catch (error) {
      throw SellerException(error.message);
    } on ApiException catch (error) {
      throw SellerException(_friendlyError(error));
    } on SellerException {
      rethrow;
    } catch (_) {
      throw SellerException(
        'Connexion au serveur impossible. Vérifiez votre réseau.',
      );
    }
  }

  /* ------------------------------------------------------------------ */
  /*  Listings                                                           */
  /* ------------------------------------------------------------------ */

  /// Publishes a new listing. Backward compatible with the existing
  /// add-product screen (defaults to a product listing in XOF).
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
      final ownerUserId = _localUserId;
      if (ownerUserId == null) {
        throw SellerException('Reconnectez-vous pour publier un produit.');
      }
      final json = await _createRemoteListing(
        ownerUserId: ownerUserId,
        categoryId: categoryId,
        categoryType: categoryType,
        title: title,
        description: description,
        price: price,
        currency: currency,
        inventory: inventory,
        imageUrl: imageUrl,
        attributes: attributes,
      );
      return Listing.fromJson(json);
    } on LocalBackendException catch (error) {
      throw SellerException(error.message);
    } on ApiException catch (error) {
      throw SellerException(_friendlyError(error));
    } on SellerException {
      rethrow;
    } catch (_) {
      throw SellerException(
        'Connexion au serveur impossible. Vérifiez votre réseau.',
      );
    }
  }

  Future<Map<String, dynamic>> _createRemoteListing({
    required String ownerUserId,
    required String categoryId,
    required String categoryType,
    required String title,
    required String description,
    required double price,
    required String currency,
    required int inventory,
    required String imageUrl,
    Map<String, dynamic>? attributes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final slug = _slug('$title-$now');
    final mergedAttributes = <String, dynamic>{
      ...?attributes,
      'partnerUserId': ownerUserId,
      'submittedFrom': 'mobile_app',
    };
    final rows = await Supabase.instance.client
        .from('listings')
        .insert({
          'vendor_id': 'vendor-1',
          'shop_id': 'shop-1',
          'category_id': categoryId,
          'category_type': categoryType,
          'slug': slug,
          'title': title.trim(),
          'description': description.trim(),
          'status': 'pending_review',
          'price': price,
          'currency': currency,
          'inventory': inventory,
          'featured': false,
          'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
          'attributes': mergedAttributes,
          'partner_user_id': ownerUserId,
        })
        .select()
        .limit(1);
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<List<Map<String, dynamic>>?> _partnerRemoteListings() async {
    final ownerUserId = _localUserId;
    if (ownerUserId == null) return null;
    final rows = await Supabase.instance.client
        .from('listings')
        .select()
        .eq('partner_user_id', ownerUserId)
        .order('created_at', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  /// Updates an existing listing (`PATCH /v1/listings/:id`). Only the
  /// provided fields are sent.
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
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (description != null) body['description'] = description.trim();
    if (price != null) body['price'] = price;
    if (currency != null) body['currency'] = currency;
    if (inventory != null) body['inventory'] = inventory;
    if (imageUrl != null) {
      body['imageUrl'] = imageUrl.trim().isEmpty ? null : imageUrl.trim();
    }
    if (attributes != null) body['attributes'] = attributes;

    try {
      final json = await LocalBackend.instance.updateListing(listingId, body);
      return Listing.fromJson(json);
    } on LocalBackendException catch (error) {
      throw RepositoryException(error.message);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /* ------------------------------------------------------------------ */
  /*  Seller orders                                                      */
  /* ------------------------------------------------------------------ */

  /// Orders containing items sold by [vendorId].
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

  /// Updates the status of one of the vendor's orders.
  Future<Order> updateOrderStatus(
    String vendorId,
    String orderId, {
    required String status,
    String? trackingNumber,
  }) async {
    _requireToken();
    throw SellerException('Commande locale introuvable.');
  }

  String _friendlyError(ApiException error) {
    final parsed = RepositoryErrorMapper.messageFromBody(error.message);
    switch (error.statusCode) {
      case 401:
        return 'Votre session a expiré. Reconnectez-vous pour continuer.';
      case 403:
        return parsed ??
            'Vous devez finaliser votre boutique avant cette action.';
      case 409:
        return parsed ?? 'Une boutique existe déjà pour ce compte.';
      case 422:
      case 400:
        return parsed ?? 'Données invalides. Vérifiez le formulaire.';
      default:
        return parsed ?? 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  String? get _localUserId {
    final token = _accessToken;
    if (token == null || !token.startsWith('local:')) return null;
    return token.substring('local:'.length);
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
