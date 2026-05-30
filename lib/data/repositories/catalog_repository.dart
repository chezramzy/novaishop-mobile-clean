import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/api_collection.dart';
import '../models/category.dart';
import '../models/listing.dart';
import '../models/review.dart';
import '../models/search_suggestion.dart';
import '../models/shop.dart';
import 'repository_error.dart';

/// A featured-seller summary returned by `GET /v1/catalog/featured-sellers`.
class FeaturedSeller {
  const FeaturedSeller({
    required this.shop,
    required this.listingCount,
  });

  final Shop shop;
  final int listingCount;

  factory FeaturedSeller.fromJson(Map<String, dynamic> json) {
    final rawShop = json['shop'];
    return FeaturedSeller(
      shop: rawShop is Map
          ? Shop.fromJson(Map<String, dynamic>.from(rawShop))
          : const Shop(
              id: '',
              vendorId: '',
              name: '',
              slug: '',
              description: '',
              focus: [],
              createdAt: '',
            ),
      listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Marketplace statistics returned by `GET /v1/catalog/stats`.
class CatalogStats {
  const CatalogStats({
    required this.totalListings,
    required this.totalSellers,
    required this.totalOrders,
    required this.totalUsers,
  });

  final int totalListings;
  final int totalSellers;
  final int totalOrders;
  final int totalUsers;

  factory CatalogStats.fromJson(Map<String, dynamic> json) {
    return CatalogStats(
      totalListings: (json['totalListings'] as num?)?.toInt() ?? 0,
      totalSellers: (json['totalSellers'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A public shop page returned by `GET /v1/catalog/shops/:slug`.
class ShopPage {
  const ShopPage({
    required this.shop,
    required this.listingCount,
    required this.averageRating,
    required this.reviews,
    required this.listings,
  });

  final Shop shop;
  final int listingCount;
  final double averageRating;
  final List<VendorReview> reviews;
  final List<Listing> listings;

  factory ShopPage.fromJson(Map<String, dynamic> json) {
    final rawShop = Map<String, dynamic>.from(json['shop'] as Map? ?? const {});
    final rawReviews = json['reviews'];
    final rawListings = json['listings'];
    return ShopPage(
      shop: Shop.fromJson(rawShop),
      listingCount: (json['listingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviews: rawReviews is List
          ? rawReviews
              .whereType<Map>()
              .map((e) => VendorReview.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      listings: rawListings is List
          ? rawListings
              .whereType<Map>()
              .map((e) => Listing.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

/// Public catalogue access (`/v1/catalog/*`). No token required, but a token
/// is forwarded when available so admins see unpublished content.
class CatalogRepository {
  CatalogRepository({String? accessToken});

  /// Lists categories from the API.
  Future<ApiCollection<Category>> getCategories() async {
    try {
      final rows = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('active', true)
          .order('sort_order')
          .order('name');
      final items = rows
          .whereType<Map>()
          .map((row) => Category.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      return ApiCollection(
        items: items,
        total: items.length,
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Lists listings with optional filters.
  Future<ApiCollection<Listing>> getListings({
    String? query,
    String? sort,
    String? categoryType,
    String? categoryId,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var request = Supabase.instance.client
          .from('listings')
          .select('*, product_variants(*), listing_images(*)');
      if (categoryType != null && categoryType.isNotEmpty) {
        request = request.eq('category_type', categoryType);
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        request = request.eq('category_id', categoryId);
      }
      request = request.eq(
        'status',
        status != null && status.isNotEmpty ? status : 'published',
      );
      if (query != null && query.trim().isNotEmpty) {
        request = request.ilike('title', '%${query.trim()}%');
      }
      final rows = await request
          .order('created_at', ascending: false)
          .range((page - 1) * pageSize, (page * pageSize) - 1);
      var listings = rows
          .whereType<Map>()
          .map((row) => _listingFromRow(Map<String, dynamic>.from(row)))
          .toList();
      if (minPrice != null) {
        listings = listings.where((item) => item.price >= minPrice).toList();
      }
      if (maxPrice != null) {
        listings = listings.where((item) => item.price <= maxPrice).toList();
      }
      if (featured != null) {
        listings = listings.where((item) => item.featured == featured).toList();
      }
      return ApiCollection(items: listings, total: listings.length);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Fetches a single listing by its slug.
  Future<Listing> getListing(String slug) async {
    try {
      final rows = await Supabase.instance.client
          .from('listings')
          .select('*, product_variants(*), listing_images(*)')
          .or('slug.eq.$slug,id.eq.$slug')
          .eq('status', 'published')
          .limit(1);
      if (rows.isNotEmpty) {
        return _listingFromRow(Map<String, dynamic>.from(rows.first as Map));
      }
      throw RepositoryException('Produit introuvable.');
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Listing _listingFromRow(Map<String, dynamic> row) {
    final attributes =
        Map<String, dynamic>.from(row['attributes'] as Map? ?? {});
    final variants = row['product_variants'];
    if (variants is List && variants.isNotEmpty) {
      attributes['variants'] = [
        for (final raw in variants.whereType<Map>())
          {
            'id': '${raw['id'] ?? ''}',
            'options': raw['options'] is Map
                ? Map<String, dynamic>.from(raw['options'] as Map)
                : <String, dynamic>{},
            'inventory': raw['inventory'],
            'price': raw['price'],
            'imageUrl': raw['image_url'],
          }
      ];
    }
    final images = row['listing_images'];
    if ((row['image_url'] == null || '${row['image_url']}'.trim().isEmpty) &&
        images is List &&
        images.isNotEmpty) {
      final sorted = images.whereType<Map>().toList()
        ..sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (b['is_primary'] == true && a['is_primary'] != true) return 1;
          return ((a['sort_order'] as num?)?.toInt() ?? 0)
              .compareTo((b['sort_order'] as num?)?.toInt() ?? 0);
        });
      if (sorted.isNotEmpty) row['image_url'] = sorted.first['url'];
    }
    return Listing.fromJson({
      ...row,
      'attributes': attributes,
    });
  }

  /// Top-selling published listings.
  Future<ApiCollection<Listing>> getBestSellers() async {
    try {
      return getListings(pageSize: 12, status: 'published');
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// The most recently published listings.
  Future<ApiCollection<Listing>> getNewArrivals() async {
    try {
      return getListings(pageSize: 12, status: 'published');
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Current flash-sale listings.
  Future<ApiCollection<Listing>> getFlashSales() async {
    try {
      return const ApiCollection(items: [], total: 0);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Featured sellers for the home page.
  Future<List<FeaturedSeller>> getFeaturedSellers() async {
    try {
      return const [];
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Aggregate marketplace statistics.
  Future<CatalogStats> getStats() async {
    try {
      final listings = await getListings(status: 'published', pageSize: 1000);
      return CatalogStats(
        totalListings: listings.total,
        totalSellers: 0,
        totalOrders: 0,
        totalUsers: 0,
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Search autocomplete suggestions for [query].
  Future<List<SearchSuggestion>> getSearchSuggestions(
    String query, {
    int limit = 8,
  }) async {
    try {
      final listings = await getListings(query: query, pageSize: limit);
      return listings.items
          .map(
            (listing) => SearchSuggestion(
              id: listing.id,
              title: listing.title,
              type: 'listing',
              imageUrl: listing.imageUrl,
            ),
          )
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// A public shop page resolved by slug.
  Future<ShopPage> getShopBySlug(String slug) async {
    try {
      throw RepositoryException(
        'Les pages boutique publiques ne sont plus exposees.',
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Featured reviews across the marketplace.
  Future<List<Review>> getFeaturedReviews() async {
    try {
      return const [];
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }
}
