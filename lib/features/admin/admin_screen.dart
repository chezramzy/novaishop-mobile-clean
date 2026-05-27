import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/components/nova_image.dart';
import '../../design/design_system.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Listing>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Listing>> _load() {
    return context.read<AdminRepository>().getPendingListings();
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _approve(Listing listing) async {
    try {
      await context.read<AdminRepository>().approveListing(listing.id);
      if (!mounted) return;
      _toast('Produit valide.');
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) _toast(error.message, error: true);
    }
  }

  Future<void> _reject(Listing listing) async {
    try {
      await context.read<AdminRepository>().rejectListing(listing.id);
      if (!mounted) return;
      _toast('Produit refuse.');
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) _toast(error.message, error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? AppColors.danger : AppColors.deepInk,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Listing>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const NovaLoadingView(label: 'Chargement moderation...');
            }
            if (snapshot.hasError) {
              return NovaErrorState(
                message: 'Impossible de charger les produits en attente.',
                onRetry: _reload,
              );
            }
            final listings = snapshot.requireData;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                const ScreenHeader(title: 'Administration'),
                const SizedBox(height: AppSpacing.md),
                SectionHeader(
                  title: 'Produits en attente',
                  actionLabel: '${listings.length}',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (listings.isEmpty)
                  const NovaEmptyState(
                    icon: Icons.verified_outlined,
                    title: 'Rien a valider',
                    message:
                        'Les prochains produits partenaires apparaitront ici.',
                  )
                else
                  for (final listing in listings) ...[
                    _PendingListingCard(
                      listing: listing,
                      onApprove: () => _approve(listing),
                      onReject: () => _reject(listing),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PendingListingCard extends StatelessWidget {
  const _PendingListingCard({
    required this.listing,
    required this.onApprove,
    required this.onReject,
  });

  final Listing listing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: NovaImage(
                  url: listing.displayImage,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  placeholder: const ColoredBox(color: AppColors.butter),
                  error: const ColoredBox(
                    color: AppColors.butter,
                    child: Icon(Icons.image_outlined),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.subtitle.copyWith(
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${formatPrice(listing.price)} · Stock ${listing.inventory}',
                      style: AppTypography.caption.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    const NovaBadge(
                      label: 'En attente',
                      tone: NovaBadgeTone.warning,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            listing.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: NovaButton.secondary(
                  label: 'Refuser',
                  icon: Icons.close_rounded,
                  onPressed: onReject,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: NovaButton.primary(
                  label: 'Valider',
                  icon: Icons.check_rounded,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
