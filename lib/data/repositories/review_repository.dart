import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review.dart';
import 'repository_error.dart';

class ReviewRepository {
  ReviewRepository({required String? accessToken}) : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession() {
    if (!_hasSession) {
      throw RepositoryException(
        'Reconnectez-vous pour publier un avis.',
      );
    }
  }

  Future<List<Review>> getListingReviews(String listingId) async {
    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .select()
          .eq('listing_id', listingId)
          .order('created_at', ascending: false);
      return rows
          .whereType<Map>()
          .map((row) => Review.fromJson(_reviewJson(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Review> createListingReview({
    required String listingId,
    required int rating,
    required String comment,
  }) async {
    _requireSession();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .insert({
            'listing_id': listingId,
            'customer_id': user.id,
            'customer_name': _customerName(user),
            'rating': rating,
            'comment': comment.trim(),
          })
          .select()
          .limit(1);
      return Review.fromJson(_reviewJson(rows.first as Map));
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<Review>> getFeaturedReviews() async {
    try {
      final rows = await Supabase.instance.client
          .from('reviews')
          .select()
          .order('created_at', ascending: false)
          .limit(6);
      return rows
          .whereType<Map>()
          .map((row) => Review.fromJson(_reviewJson(row)))
          .toList();
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<List<VendorReview>> getVendorReviews(String vendorId) async {
    throw RepositoryException(
      'Les avis partenaires ne sont pas exposes dans NovaShop.',
    );
  }

  Future<VendorReview> createVendorReview({
    required String vendorId,
    required int rating,
    required String comment,
    String? orderId,
  }) async {
    throw RepositoryException(
      'Les avis partenaires ne sont pas exposes dans NovaShop.',
    );
  }

  String _customerName(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = metadata['name'] ?? metadata['full_name'];
    if (name is String && name.trim().isNotEmpty) return name.trim();
    final email = user.email;
    if (email != null && email.trim().isNotEmpty) return email.trim();
    return 'Client NovaShop';
  }

  Map<String, dynamic> _reviewJson(Map row) {
    final json = Map<String, dynamic>.from(row);
    return {
      ...json,
      'listingId': json['listing_id'],
      'customerId': json['customer_id'],
      'customerName': json['customer_name'],
      'createdAt': json['created_at'],
    };
  }
}
