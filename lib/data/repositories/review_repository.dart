import '../models/review.dart';
import 'repository_error.dart';

class ReviewRepository {
  ReviewRepository({required String? accessToken});

  final _listingReviews = <String, List<Review>>{};
  final _vendorReviews = <String, List<VendorReview>>{};

  Future<List<Review>> getListingReviews(String listingId) async {
    return List.unmodifiable(_listingReviews[listingId] ?? const []);
  }

  Future<Review> createListingReview({
    required String listingId,
    required int rating,
    required String comment,
  }) async {
    final review = Review.fromJson({
      'id': 'review-${DateTime.now().microsecondsSinceEpoch}',
      'listingId': listingId,
      'customerId': 'local',
      'customerName': 'Client NovAiShop',
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    _listingReviews.putIfAbsent(listingId, () => []).add(review);
    return review;
  }

  Future<List<Review>> getFeaturedReviews() async => const [];

  Future<List<VendorReview>> getVendorReviews(String vendorId) async {
    return List.unmodifiable(_vendorReviews[vendorId] ?? const []);
  }

  Future<VendorReview> createVendorReview({
    required String vendorId,
    required int rating,
    required String comment,
    String? orderId,
  }) async {
    throw RepositoryException(
        'Les avis boutique locaux seront ajoutes ensuite.');
  }
}
