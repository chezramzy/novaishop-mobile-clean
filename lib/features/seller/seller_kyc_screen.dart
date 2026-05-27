import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/seller_dashboard.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../data/repositories/seller_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'widgets/seller_upload.dart';
import 'widgets/seller_widgets.dart';

/// KYC document centre: the seller uploads identity, business and address
/// proofs. Files are signed and uploaded into the private KYC bucket via
/// [MediaRepository]. Existing documents come from the dashboard snapshot.
class SellerKycScreen extends StatefulWidget {
  const SellerKycScreen({this.dashboard, super.key});

  final SellerDashboardSummary? dashboard;

  @override
  State<SellerKycScreen> createState() => _SellerKycScreenState();
}

class _SellerKycScreenState extends State<SellerKycScreen> {
  late Future<SellerDashboardSummary?> _future;
  String? _uploadingType;

  static const _docTypes = <(String, String, IconData)>[
    ('identity', "Pièce d'identité", Icons.badge_outlined),
    ('business', 'Justificatif d\'entreprise', Icons.business_outlined),
    ('address', 'Justificatif de domicile', Icons.home_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _future = widget.dashboard != null
        ? Future<SellerDashboardSummary?>.value(widget.dashboard)
        : _load();
  }

  Future<SellerDashboardSummary?> _load() {
    final repository = SellerRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    return repository.getDashboard();
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _uploadDocument(String documentType) async {
    if (_uploadingType != null) return;
    final media = MediaRepository(
      accessToken: context.read<AuthController>().accessToken,
    );
    final picked = await SellerUploadPicker.pickDocument();
    if (picked == null) return;

    setState(() => _uploadingType = documentType);
    try {
      final target = await media.signUpload(
        bucket: 'private-kyc',
        fileName: picked.fileName,
        contentType: picked.contentType,
        kind: 'kyc_document',
        documentType: documentType,
      );
      await media.uploadBytes(target, picked.bytes);
      if (!mounted) return;
      showSellerSnack(
        context,
        'Document envoyé. Il sera vérifié par notre équipe.',
      );
      _reload();
    } on RepositoryException catch (error) {
      if (mounted) showSellerSnack(context, error.message, error: true);
    } catch (_) {
      if (mounted) {
        showSellerSnack(
          context,
          "L'envoi du document a échoué. Réessayez.",
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  KycDocument? _documentFor(
    List<KycDocument> documents,
    String documentType,
  ) {
    final matching =
        documents.where((doc) => doc.documentType == documentType).toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matching.first;
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: FutureBuilder<SellerDashboardSummary?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovaLoadingView(label: 'Chargement…');
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return NovaErrorState(
              message: error is RepositoryException
                  ? error.message
                  : 'Impossible de charger vos documents.',
              onRetry: _reload,
            );
          }
          final dashboard = snapshot.data;
          if (dashboard == null) {
            return NovaEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Espace partenaire requis',
              message: 'Ouvrez d\'abord votre espace pour soumettre vos '
                  'documents KYC.',
              actionLabel: 'Retour',
              onAction: () => Navigator.of(context).maybePop(),
            );
          }
          return _buildBody(dashboard);
        },
      ),
    );
  }

  Widget _buildBody(SellerDashboardSummary dashboard) {
    final documents = dashboard.kycDocuments;
    final kycStatus = dashboard.vendor.kycStatus;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: StaggeredEntrance.all([
        const ScreenHeader(title: 'Vérification KYC'),
        const SizedBox(height: AppSpacing.md),
        _KycStatusCard(status: kycStatus),
        const SizedBox(height: AppSpacing.md),
        const SellerInfoBanner(
          icon: Icons.lock_outline_rounded,
          message: 'Vos documents sont stockés de manière sécurisée et privée. '
              'Ils servent uniquement à vérifier votre identité.',
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Documents à fournir',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final docType in _docTypes) ...[
          _KycDocumentTile(
            title: docType.$2,
            icon: docType.$3,
            document: _documentFor(documents, docType.$1),
            uploading: _uploadingType == docType.$1,
            onUpload: () => _uploadDocument(docType.$1),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ]),
    );
  }
}

class _KycStatusCard extends StatelessWidget {
  const _KycStatusCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, message, icon, color) = switch (status) {
      'approved' => (
          'Vérification approuvée',
          'Votre identité est vérifiée. Les versements sont actifs.',
          Icons.verified_rounded,
          AppColors.success,
        ),
      'rejected' => (
          'Documents refusés',
          'Certains documents ont été refusés. Renvoyez vos justificatifs.',
          Icons.error_outline_rounded,
          AppColors.danger,
        ),
      'under_review' || 'submitted' => (
          'Vérification en cours',
          'Vos documents sont en cours d\'examen par notre équipe.',
          Icons.hourglass_top_rounded,
          AppColors.warning,
        ),
      _ => (
          'Vérification à compléter',
          'Envoyez vos documents pour activer les versements.',
          Icons.upload_file_outlined,
          AppColors.info,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.deepInk,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFBFC6BF),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KycDocumentTile extends StatelessWidget {
  const _KycDocumentTile({
    required this.title,
    required this.icon,
    required this.document,
    required this.uploading,
    required this.onUpload,
  });

  final String title;
  final IconData icon;
  final KycDocument? document;
  final bool uploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final doc = document;
    return NovaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: context.colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      doc == null
                          ? 'Aucun document envoyé'
                          : 'Document transmis',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (doc != null) NovaStatusBadge(status: doc.status, dense: true),
            ],
          ),
          if (doc?.status == 'rejected' &&
              (doc?.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.colors.blush,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'Motif : ${doc!.rejectionReason}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          NovaButton.secondary(
            label:
                doc == null ? 'Envoyer le document' : 'Remplacer le document',
            icon: Icons.upload_file_outlined,
            busy: uploading,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}
