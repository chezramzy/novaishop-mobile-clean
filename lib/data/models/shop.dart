import 'json_utils.dart';

/// A seller's public shop (`Shop` interface).
class Shop {
  const Shop({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.slug,
    required this.description,
    required this.focus,
    required this.createdAt,
    this.tagline,
    this.supportEmail,
    this.supportPhone,
    this.country,
    this.city,
  });

  final String id;
  final String vendorId;
  final String name;
  final String slug;
  final String description;
  final String? tagline;

  /// Category types the shop focuses on: `product`, `service`, `property`.
  final List<String> focus;
  final String? supportEmail;
  final String? supportPhone;
  final String? country;
  final String? city;
  final String createdAt;

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: Json.str(json['id']),
      vendorId: Json.str(json['vendorId']),
      name: Json.str(json['name']),
      slug: Json.str(json['slug']),
      description: Json.str(json['description']),
      tagline: Json.strOrNull(json['tagline']),
      focus: Json.stringList(json['focus']),
      supportEmail: Json.strOrNull(json['supportEmail']),
      supportPhone: Json.strOrNull(json['supportPhone']),
      country: Json.strOrNull(json['country']),
      city: Json.strOrNull(json['city']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
