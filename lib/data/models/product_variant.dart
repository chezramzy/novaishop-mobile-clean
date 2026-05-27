import 'json_utils.dart';

/// A sellable product option owned by NovaShop's unified catalogue.
///
/// Partner attribution stays internal; the client only sees the option label,
/// price and stock exposed here.
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.options,
    required this.inventory,
    this.price,
    this.imageUrl,
  });

  final String id;
  final Map<String, String> options;
  final int inventory;
  final double? price;
  final String? imageUrl;

  bool get isInStock => inventory > 0;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final rawOptions = Json.obj(json['options']);
    return ProductVariant(
      id: Json.str(json['id']),
      options: rawOptions.map((key, value) => MapEntry(key, '$value')),
      inventory: Json.integer(json['inventory']),
      price: Json.dblOrNull(json['price']),
      imageUrl: Json.strOrNull(json['imageUrl']),
    );
  }
}
