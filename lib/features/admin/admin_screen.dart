import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/formatters.dart';
import '../../data/models/listing.dart';
import '../../data/models/partner_application.dart';
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
  late Future<_AdminData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AdminData> _load() async {
    final repository = context.read<AdminRepository>();
    final results = await Future.wait([
      repository.getPartnerApplications(),
      repository.getPendingListings(),
    ]);
    return _AdminData(
      applications: results[0] as List<PartnerApplication>,
      listings: results[1] as List<Listing>,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _setReviewing(PartnerApplication application) async {
    try {
      await context
          .read<AdminRepository>()
          .markApplicationReviewing(application.id);
      if (!mounted) return;
      _toast('Demande mise en analyse.');
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) _toast(error.message, error: true);
    }
  }

  Future<void> _reviewApplication(
    PartnerApplication application, {
    required bool approve,
  }) async {
    final note = await _askNote(
      title: approve ? 'Approuver la demande' : 'Refuser la demande',
      hint:
          approve ? 'Note interne facultative' : 'Expliquez la raison du refus',
    );
    if (note == null) return;
    if (!mounted) return;
    try {
      await context.read<AdminRepository>().reviewPartnerApplication(
            application.id,
            approve: approve,
            note: note,
          );
      if (!mounted) return;
      _toast(approve ? 'Demande approuvee.' : 'Demande refusee.');
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) _toast(error.message, error: true);
    }
  }

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

  Future<String?> _askNote({
    required String title,
    required String hint,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
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
    return DefaultTabController(
      length: 2,
      child: SoftGradientScaffold(
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: FutureBuilder<_AdminData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const NovaLoadingView(label: 'Chargement admin...');
              }
              if (snapshot.hasError) {
                return NovaErrorState(
                  message: 'Impossible de charger les donnees admin.',
                  onRetry: _reload,
                );
              }
              final data = snapshot.requireData;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        const ScreenHeader(title: 'Administration'),
                        const SizedBox(height: AppSpacing.sm),
                        TabBar(
                          labelColor: context.colors.textPrimary,
                          unselectedLabelColor: AppColors.muted,
                          indicatorColor: AppColors.lime,
                          tabs: [
                            Tab(
                              text:
                                  'Demandes (${data.openApplications.length})',
                            ),
                            Tab(text: 'Produits (${data.listings.length})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ApplicationsTab(
                          applications: data.applications,
                          onReviewing: _setReviewing,
                          onApprove: (item) =>
                              _reviewApplication(item, approve: true),
                          onReject: (item) =>
                              _reviewApplication(item, approve: false),
                        ),
                        _ListingsTab(
                          listings: data.listings,
                          onApprove: _approve,
                          onReject: _reject,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminData {
  const _AdminData({
    required this.applications,
    required this.listings,
  });

  final List<PartnerApplication> applications;
  final List<Listing> listings;

  List<PartnerApplication> get openApplications => applications
      .where((item) => item.status == 'new' || item.status == 'reviewing')
      .toList(growable: false);
}

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab({
    required this.applications,
    required this.onReviewing,
    required this.onApprove,
    required this.onReject,
  });

  final List<PartnerApplication> applications;
  final ValueChanged<PartnerApplication> onReviewing;
  final ValueChanged<PartnerApplication> onApprove;
  final ValueChanged<PartnerApplication> onReject;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const NovaEmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Aucune demande',
        message: 'Les demandes partenaires apparaitront ici.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _ApplicationCard(
        application: applications[index],
        onReviewing: () => onReviewing(applications[index]),
        onApprove: () => onApprove(applications[index]),
        onReject: () => onReject(applications[index]),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onReviewing,
    required this.onApprove,
    required this.onReject,
  });

  final PartnerApplication application;
  final VoidCallback onReviewing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final canReview = application.status == 'new';
    final canDecide =
        application.status == 'new' || application.status == 'reviewing';
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.applicantEmail.isEmpty
                      ? application.applicantUserId
                      : application.applicantEmail,
                  style: AppTypography.subtitle.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              NovaBadge(
                label: _statusLabel(application.status),
                tone: _statusTone(application.status),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'WhatsApp: ${application.whatsapp}',
            style: AppTypography.caption.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            application.productDescription,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: context.colors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final image in application.images.take(3)) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: NovaImage(
                    url: image.displayUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: const ColoredBox(color: AppColors.butter),
                    error: const ColoredBox(
                      color: AppColors.butter,
                      child: Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
          if ((application.adminNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Note: ${application.adminNotes}',
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (canReview)
                NovaButton.secondary(
                  label: 'Analyser',
                  icon: Icons.manage_search_rounded,
                  onPressed: onReviewing,
                ),
              if (canDecide)
                NovaButton.secondary(
                  label: 'Refuser',
                  icon: Icons.close_rounded,
                  onPressed: onReject,
                ),
              if (canDecide)
                NovaButton.primary(
                  label: 'Approuver',
                  icon: Icons.check_rounded,
                  onPressed: onApprove,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'approved' => 'Approuvee',
      'rejected' => 'Refusee',
      'reviewing' => 'En analyse',
      'archived' => 'Archivee',
      _ => 'Nouvelle',
    };
  }

  NovaBadgeTone _statusTone(String status) {
    return switch (status) {
      'approved' => NovaBadgeTone.success,
      'rejected' => NovaBadgeTone.danger,
      'reviewing' => NovaBadgeTone.warning,
      _ => NovaBadgeTone.info,
    };
  }
}

class _ListingsTab extends StatelessWidget {
  const _ListingsTab({
    required this.listings,
    required this.onApprove,
    required this.onReject,
  });

  final List<Listing> listings;
  final ValueChanged<Listing> onApprove;
  final ValueChanged<Listing> onReject;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const NovaEmptyState(
        icon: Icons.verified_outlined,
        title: 'Rien a valider',
        message: 'Les prochains produits partenaires apparaitront ici.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: listings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _PendingListingCard(
        listing: listings[index],
        onApprove: () => onApprove(listings[index]),
        onReject: () => onReject(listings[index]),
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
                      '${formatPrice(listing.price)} - Stock ${listing.inventory}',
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
