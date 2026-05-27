import 'json_utils.dart';
import 'product_variant.dart';

/// A catalogue listing — product, service or property.
class Listing {
  const Listing({
    required this.id,
    required this.vendorId,
    required this.shopId,
    required this.categoryId,
    required this.categoryType,
    required this.slug,
    required this.title,
    required this.description,
    required this.status,
    required this.price,
    required this.currency,
    required this.inventory,
    required this.featured,
    required this.attributes,
    this.imageUrl,
    this.originalPrice,
    this.isFlashSale = false,
    this.flashSaleEndAt,
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;

  /// Internal partner attribution. Kept for partner operations, never shown
  /// in the public customer experience.
  final String vendorId;

  /// Deprecated public-shop alias retained while partner routes migrate.
  final String shopId;
  final String categoryId;

  /// One of: `product`, `service`, `property`.
  final String categoryType;
  final String slug;
  final String title;
  final String description;

  /// One of: `draft`, `pending_review`, `published`, `rejected`, `archived`.
  final String status;
  final double price;
  final String currency;
  final int inventory;
  final bool featured;
  final String? imageUrl;
  final Map<String, dynamic> attributes;
  final double? originalPrice;
  final bool isFlashSale;
  final String? flashSaleEndAt;
  final String createdAt;
  final String updatedAt;

  bool get isPublished => status == 'published';
  bool get isInStock => inventory > 0;
  String get partnerId => vendorId;

  List<ProductVariant> get variants {
    final raw = attributes['variants'] ?? attributes['productVariants'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ProductVariant.fromJson(Map<String, dynamic>.from(item)))
        .where((variant) => variant.id.isNotEmpty)
        .toList(growable: false);
  }

  /// Discount percentage when a strike-through original price is present.
  int? get discountPercent {
    final original = originalPrice;
    if (original == null || original <= price) return null;
    return (((original - price) / original) * 100).round();
  }

  String get displayImage {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    return '';
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: Json.str(json['id']),
      vendorId: Json.str(json['vendorId'] ?? json['vendor_id']),
      shopId: Json.str(json['shopId'] ?? json['shop_id']),
      categoryId: Json.str(json['categoryId'] ?? json['category_id']),
      categoryType:
          Json.str(json['categoryType'] ?? json['category_type'], 'product'),
      slug: Json.str(json['slug']),
      title: Json.str(json['title']),
      description: Json.str(json['description']),
      status: Json.str(json['status'], 'published'),
      price: Json.dbl(json['price']),
      currency: Json.str(json['currency'], 'XOF'),
      inventory: Json.integer(json['inventory']),
      featured: Json.boolean(json['featured']),
      imageUrl: Json.strOrNull(json['imageUrl'] ?? json['image_url']),
      attributes: Json.obj(json['attributes']),
      originalPrice:
          Json.dblOrNull(json['originalPrice'] ?? json['original_price']),
      isFlashSale: Json.boolean(json['isFlashSale'] ?? json['is_flash_sale']),
      flashSaleEndAt:
          Json.strOrNull(json['flashSaleEndAt'] ?? json['flash_sale_end_at']),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
      updatedAt: Json.str(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
