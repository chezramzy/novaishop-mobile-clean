import '../models/json_utils.dart';

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String listingId;
  final String createdAt;

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      listingId: Json.str(json['listingId']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

class WishlistRepository {
  WishlistRepository({required String? accessToken});

  final _items = <String, WishlistItem>{};

  Future<List<WishlistItem>> getWishlist() async => _items.values.toList();

  Future<WishlistItem> addToWishlist(String listingId) async {
    final item = WishlistItem(
      id: 'wish-${DateTime.now().microsecondsSinceEpoch}',
      userId: 'local',
      listingId: listingId,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    _items[listingId] = item;
    return item;
  }

  Future<void> removeFromWishlist(String listingId) async {
    _items.remove(listingId);
  }
}
