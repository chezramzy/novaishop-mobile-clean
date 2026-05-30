import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/json_utils.dart';
import 'repository_error.dart';

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
      userId: Json.str(json['userId'] ?? json['user_id']),
      listingId: Json.str(json['listingId'] ?? json['listing_id']),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
    );
  }
}

class WishlistRepository {
  WishlistRepository({required String? accessToken})
      : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentUser != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession() {
    if (!_hasSession) {
      throw RepositoryException(
        "Reconnectez-vous pour gerer votre liste d'envies.",
      );
    }
  }

  Future<List<WishlistItem>> getWishlist() async {
    _requireSession();
    try {
      final rows = await Supabase.instance.client
          .from('wishlist_items')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => WishlistItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<WishlistItem> addToWishlist(String listingId) async {
    _requireSession();
    try {
      final row = await Supabase.instance.client
          .from('wishlist_items')
          .upsert(
            {
              'user_id': _userId,
              'listing_id': listingId,
            },
            onConflict: 'user_id,listing_id',
          )
          .select()
          .single();
      return WishlistItem.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<void> removeFromWishlist(String listingId) async {
    _requireSession();
    try {
      await Supabase.instance.client
          .from('wishlist_items')
          .delete()
          .eq('user_id', _userId)
          .eq('listing_id', listingId);
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  String get _userId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    return id;
  }
}
