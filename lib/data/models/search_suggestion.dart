import 'json_utils.dart';

/// A search autocomplete suggestion (`SearchSuggestion` interface).
class SearchSuggestion {
  const SearchSuggestion({
    required this.id,
    required this.title,
    required this.type,
    this.subtitle,
    this.imageUrl,
  });

  final String id;
  final String title;

  /// `listing`, `category` or `vendor`.
  final String type;
  final String? subtitle;
  final String? imageUrl;

  bool get isListing => type == 'listing';
  bool get isCategory => type == 'category';
  bool get isVendor => type == 'vendor';

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      id: Json.str(json['id']),
      title: Json.str(json['title']),
      type: Json.str(json['type'], 'listing'),
      subtitle: Json.strOrNull(json['subtitle']),
      imageUrl: Json.strOrNull(json['imageUrl']),
    );
  }
}
