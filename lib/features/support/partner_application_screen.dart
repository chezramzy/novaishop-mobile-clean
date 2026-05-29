import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/partner_application.dart';
import '../../data/repositories/partner_application_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_redirect.dart';
import '../seller/widgets/seller_upload.dart';

class PartnerApplicationScreen extends StatefulWidget {
  const PartnerApplicationScreen({super.key});

  @override
  State<PartnerApplicationScreen> createState() =>
      _PartnerApplicationScreenState();
}

class _PartnerApplicationScreenState extends State<PartnerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _whatsapp = TextEditingController();
  final _description = TextEditingController();
  final _images = <PartnerApplicationImage>[];
  Future<PartnerApplication?>? _latestFuture;
  String? _latestUserId;
  bool _submitting = false;

  @override
  void dispose() {
    _whatsapp.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;
    final picked = await SellerUploadPicker.pickGalleryImage();
    if (picked == null) return;
    setState(() {
      _images.add(
        PartnerApplicationImage(
          bytes: picked.bytes,
          fileName: picked.fileName,
          contentType: picked.contentType,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.length != 3) {
      _toast('Ajoutez exactement 3 images de produits.', error: true);
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    try {
      await context.read<PartnerApplicationRepository>().submit(
            whatsapp: _whatsapp.text,
            productDescription: _description.text,
            images: _images,
            applicantUserId: auth.user?.id,
            applicantEmail: auth.user?.email,
          );
      if (!mounted) return;
      _toast('Demande envoyee. Vous pouvez suivre son statut ici.');
      _refreshLatest(auth.user?.id ?? '');
    } catch (error) {
      if (!mounted) return;
      _toast(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _refreshLatest(String userId) {
    setState(() {
      _latestUserId = userId;
      _latestFuture =
          context.read<PartnerApplicationRepository>().getLatestForUser(userId);
    });
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
    final auth = context.watch<AuthController>();
    if (!auth.isAuthenticated) {
      return const _PartnerAccountGate();
    }
    final userId = auth.user?.id ?? '';
    if (_latestFuture == null || _latestUserId != userId) {
      _latestUserId = userId;
      _latestFuture =
          context.read<PartnerApplicationRepository>().getLatestForUser(userId);
    }

    return SoftGradientScaffold(
      child: FutureBuilder<PartnerApplication?>(
        future: _latestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NovaErrorState(
              message: 'Impossible de charger votre demande partenaire.',
              onRetry: () => _refreshLatest(userId),
            );
          }
          final application = snapshot.data;
          if (application != null) {
            return _ApplicationStatusView(application: application);
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                40 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                const ScreenHeader(title: 'Devenir partenaire'),
                const SizedBox(height: AppSpacing.lg),
                const _IntroCard(),
                const SizedBox(height: AppSpacing.lg),
                NovaCard(
                  child: Column(
                    children: [
                      NovaTextField(
                        controller: _whatsapp,
                        label: 'Numero WhatsApp',
                        hint: '+229 01 00 00 00 00',
                        icon: Icons.chat_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'Le numero WhatsApp est requis.';
                          }
                          if (text.length < 8) return 'Numero trop court.';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NovaTextField(
                        controller: _description,
                        label: 'Produits vendus',
                        hint:
                            'Decrivez vos categories, marques, prix moyens, stock...',
                        minLines: 5,
                        maxLines: 8,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return 'La description est requise.';
                          }
                          if (text.length < 30) {
                            return 'Decrivez un peu plus vos produits.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Images produits',
                  actionLabel: '${_images.length}/3',
                ),
                const SizedBox(height: AppSpacing.sm),
                _ImageGrid(
                  images: _images,
                  onAdd: _pickImage,
                  onRemove: (index) => setState(() => _images.removeAt(index)),
                ),
                const SizedBox(height: AppSpacing.lg),
                NovaButton.primary(
                  label: 'Envoyer ma demande',
                  icon: Icons.send_rounded,
                  busy: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationStatusView extends StatelessWidget {
  const _ApplicationStatusView({required this.application});

  final PartnerApplication application;

  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final (label, message, icon) = switch (status) {
      'approved' => (
          'Demande approuvee',
          'Votre espace partenaire est maintenant debloque pour ajouter vos produits.',
          Icons.verified_rounded,
        ),
      'rejected' => (
          'Demande refusee',
          'NovaShop a examine votre dossier. Contactez le support si vous souhaitez comprendre la decision.',
          Icons.cancel_outlined,
        ),
      'reviewing' => (
          'Demande en analyse',
          'L equipe NovaShop verifie vos produits. Vous serez notifie des que le statut change.',
          Icons.manage_search_rounded,
        ),
      _ => (
          'Demande envoyee',
          'Votre dossier est bien recu. Vous recevrez une notification quand NovaShop aura termine l analyse.',
          Icons.hourglass_top_rounded,
        ),
    };
    final createdAt = application.createdAt;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        40 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        const ScreenHeader(title: 'Devenir partenaire'),
        const SizedBox(height: AppSpacing.lg),
        NovaCard(
          color: status == 'approved' ? AppColors.deepInk : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: status == 'approved'
                    ? AppColors.lime
                    : context.colors.textPrimary,
                size: 34,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                style: AppTypography.title.copyWith(
                  color: status == 'approved'
                      ? Colors.white
                      : context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: AppTypography.body.copyWith(
                  color: status == 'approved'
                      ? Colors.white.withValues(alpha: .78)
                      : context.colors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Soumise le $createdAt',
                  style: AppTypography.caption.copyWith(
                    color: status == 'approved'
                        ? Colors.white.withValues(alpha: .58)
                        : context.colors.textSecondary,
                  ),
                ),
              ],
              if (status == 'approved') ...[
                const SizedBox(height: AppSpacing.lg),
                NovaButton.primary(
                  label: 'Ouvrir l espace partenaire',
                  icon: Icons.add_business_rounded,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.partnerHome),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return const NovaCard(
      color: AppColors.deepInk,
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: AppColors.lime),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'NovaShop examine votre demande puis vous contacte sur WhatsApp '
              'si vos produits correspondent au catalogue.',
              style: TextStyle(color: Colors.white, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerAccountGate extends StatelessWidget {
  const _PartnerAccountGate();

  static const _redirect = AuthRedirect(
    routeName: RouteNames.partnerApplication,
    signUpRole: AccountRole.individualBuyer,
  );

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          40 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          const ScreenHeader(title: 'Devenir partenaire'),
          const SizedBox(height: AppSpacing.lg),
          NovaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Commencez par un compte client',
                  style: AppTypography.title.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Votre demande partenaire sera rattachee a ce compte. Vous '
                  'pourrez suivre son statut, recevoir les notifications et '
                  'acceder a l espace partenaire apres validation.',
                  style: AppTypography.body.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                NovaButton.primary(
                  label: 'Creer mon compte client',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => Navigator.of(context).pushNamed(
                    RouteNames.signUp,
                    arguments: _redirect,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                NovaButton.secondary(
                  label: 'J ai deja un compte',
                  icon: Icons.login_rounded,
                  onPressed: () => Navigator.of(context).pushNamed(
                    RouteNames.signIn,
                    arguments: _redirect,
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

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PartnerApplicationImage> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
      ),
      itemBuilder: (context, index) {
        if (index >= images.length) {
          return InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: onAdd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: context.colors.border),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined),
            ),
          );
        }
        final image = images[index];
        final bytes = image.bytes;
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: bytes == null
                    ? const ColoredBox(color: AppColors.butter)
                    : Image.memory(bytes, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: SizedBox.square(
                dimension: 28,
                child: IconButton.filled(
                  padding: EdgeInsets.zero,
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
