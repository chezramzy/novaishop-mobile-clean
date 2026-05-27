import '../../core/local_backend/local_backend.dart';
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
      final items = await LocalBackend.instance.categories();
      return ApiCollection(
        items: items.map(Category.fromJson).toList(),
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
      final items = await LocalBackend.instance.listings(
        query: query,
        categoryType: categoryType,
        categoryId: categoryId,
        status: status,
        page: page,
        pageSize: pageSize,
      );
      var listings = items.map(Listing.fromJson).toList();
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
      final json = await LocalBackend.instance.listingBySlug(slug);
      return Listing.fromJson(json);
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw RepositoryErrorMapper.wrap(error);
    }
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
      final listings = await LocalBackend.instance.listings(pageSize: 1000);
      return CatalogStats(
        totalListings: listings.length,
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
      throw RepositoryException('Boutique indisponible en mode local.');
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
