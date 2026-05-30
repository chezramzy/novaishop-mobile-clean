import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_error.dart';
import '../../data/repositories/review_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'review_widgets.dart';
import 'write_review_screen.dart';

/// Arguments passed to the reviews route.
class ReviewsArgs {
  const ReviewsArgs({
    required this.targetId,
    required this.targetName,
    this.isVendor = false,
  });

  /// The listing id. Vendor reviews are blocked in the public app.
  final String targetId;

  /// The product name shown in the header.
  final String targetName;

  /// Kept for legacy route compatibility; vendor reviews are blocked.
  final bool isVendor;
}

/// The full reviews list for a product, with a write action.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({required this.args, super.key});

  final ReviewsArgs args;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<_ReviewEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_ReviewEntry>> _load() async {
    final repository = ReviewRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    if (widget.args.isVendor) {
      throw RepositoryException(
        'Les avis partenaires ne sont pas exposes dans NovaShop.',
      );
    }
    final reviews = await repository.getListingReviews(widget.args.targetId);
    return reviews
        .map((r) => _ReviewEntry(
              authorName: r.customerName,
              rating: r.rating,
              comment: r.comment,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _openWrite() async {
    final published = await openWriteReviewSheet(
      context,
      targetId: widget.args.targetId,
      targetName: widget.args.targetName,
      isVendor: widget.args.isVendor,
    );
    if (published && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Merci ! Votre avis a été publié.'),
          ),
        );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<List<_ReviewEntry>>(
        future: _future,
        builder: (context, snapshot) {
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: ScreenHeader(
              title: 'Avis clients',
              trailing: CircleIconButton(
                icon: Icons.rate_review_outlined,
                tooltip: 'Donner mon avis',
                onPressed: _openWrite,
              ),
            ),
          );

          if (snapshot.connectionState != ConnectionState.done) {
            return Column(
              children: [
                header,
                const SizedBox(height: 8),
                const Expanded(child: SkeletonList(itemCount: 6)),
              ],
            );
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                header,
                Expanded(
                  child: NovaErrorState(
                    message: snapshot.error is RepositoryException
                        ? (snapshot.error as RepositoryException).message
                        : 'Impossible de charger les avis.',
                    onRetry: _reload,
                  ),
                ),
              ],
            );
          }

          final reviews = snapshot.requireData;
          final average = reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

          return RefreshIndicator(
            color: context.colors.textPrimary,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              children: [
                ScreenHeader(
                  title: 'Avis clients',
                  trailing: CircleIconButton(
                    icon: Icons.rate_review_outlined,
                    tooltip: 'Donner mon avis',
                    onPressed: _openWrite,
                  ),
                ),
                const SizedBox(height: 18),
                NovaCard(
                  child: RatingSummary(
                    average: average,
                    count: reviews.length,
                  ),
                ).fadeSlideIn(),
                const SizedBox(height: 16),
                NovaButton.secondary(
                  label: 'Écrire un avis',
                  icon: Icons.edit_outlined,
                  onPressed: _openWrite,
                ).fadeSlideIn(delay: AppMotion.fast),
                const SizedBox(height: 20),
                if (reviews.isEmpty)
                  const NovaEmptyState(
                    icon: Icons.reviews_outlined,
                    title: 'Aucun avis',
                    message: 'Soyez le premier à partager votre expérience.',
                  )
                else
                  ...List.generate(reviews.length, (index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: StaggeredEntrance.item(
                        index,
                        ReviewTile(
                          authorName: review.authorName,
                          rating: review.rating,
                          comment: review.comment,
                          createdAt: review.createdAt,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A unified review entry covering both listing and vendor reviews.
class _ReviewEntry {
  const _ReviewEntry({
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String authorName;
  final int rating;
  final String comment;
  final String createdAt;
}
