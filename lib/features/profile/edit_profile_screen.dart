import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/router/route_names.dart';
import '../../data/models/auth_user.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';

/// Formulaire de modification du profil : photo, prénom, nom, téléphone et,
/// pour les partenaires professionnels, le nom de l'entreprise.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({this.user, super.key});

  final AuthUser? user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AuthUser? _user =
      widget.user ?? context.read<AuthController>().user;

  late final TextEditingController _firstName =
      TextEditingController(text: _user?.firstName ?? '');
  late final TextEditingController _lastName =
      TextEditingController(text: _user?.lastName ?? '');
  late final TextEditingController _phone =
      TextEditingController(text: _user?.phone ?? '');
  late final TextEditingController _businessName =
      TextEditingController(text: _user?.businessName ?? '');

  late String? _avatarUrl = _user?.avatarUrl;
  bool _busy = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _businessName.dispose();
    super.dispose();
  }

  void _snack(String message, Color background) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: background,
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
  }

  String _contentTypeFor(String fileName, String? mimeType) {
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;
    final repository = context.read<MediaRepository>();
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      final fileName = picked.name.isNotEmpty ? picked.name : 'avatar.jpg';
      final url = await repository.uploadPublicImage(
        bytes: bytes,
        fileName: fileName,
        contentType: _contentTypeFor(fileName, picked.mimeType),
      );
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      _snack('Photo importée. Enregistrez pour confirmer.', AppColors.deepInk);
    } on RepositoryException catch (error) {
      if (mounted) _snack(error.message, AppColors.danger);
    } catch (_) {
      if (mounted) {
        _snack("Impossible d'importer la photo.", AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    try {
      await context.read<AuthController>().updateProfile(
            firstName: _firstName.text,
            lastName: _lastName.text,
            phone: _phone.text,
            businessName: _businessName.text,
            avatarUrl: _avatarUrl,
          );
      if (!mounted) return;
      _snack('Profil mis à jour avec succès.', AppColors.deepInk);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        _snack(
          "Impossible d'enregistrer les modifications.",
          AppColors.danger,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return SoftGradientScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const ScreenHeader(title: 'Modifier le profil'),
            const SizedBox(height: AppSpacing.xxl),
            NovaEmptyState(
              icon: Icons.person_off_outlined,
              title: 'Session expirée',
              message: 'Reconnectez-vous pour modifier votre profil.',
              actionLabel: 'Se connecter',
              onAction: () =>
                  Navigator.of(context).pushNamed(RouteNames.signIn),
            ),
          ],
        ),
      );
    }

    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            const ScreenHeader(title: 'Modifier le profil'),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _AvatarPicker(
                avatarUrl: _avatarUrl,
                initials: user.initials,
                uploading: _uploadingPhoto,
                onTap: _pickPhoto,
              ).popIn(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton.icon(
                onPressed: _uploadingPhoto ? null : _pickPhoto,
                icon: const Icon(Icons.image_outlined, size: 16),
                label: Text(
                  _uploadingPhoto
                      ? 'Importation en cours…'
                      : 'Changer la photo de profil',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.textPrimary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            NovaCard(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: NovaTextField(
                          controller: _firstName,
                          label: 'Prénom',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.name(value, field: 'Le prénom'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: NovaTextField(
                          controller: _lastName,
                          label: 'Nom',
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              Validators.name(value, field: 'Le nom'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NovaTextField(
                    controller: _phone,
                    label: 'Numéro de téléphone',
                    hint: '+33 6 12 34 56 78',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: user.role.requiresBusinessName
                        ? TextInputAction.next
                        : TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+\s()-]'),
                      ),
                    ],
                    validator: (value) =>
                        Validators.phone(value, optional: true),
                  ),
                  if (user.role.requiresBusinessName) ...[
                    const SizedBox(height: AppSpacing.md),
                    NovaTextField(
                      controller: _businessName,
                      label: "Nom de l'entreprise",
                      icon: Icons.business_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.name(
                        value,
                        field: "Le nom de l'entreprise",
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NovaCard(
              color: context.colors.surfaceMuted,
              elevated: false,
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded,
                      size: 20, color: AppColors.muted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adresse e-mail',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: AppColors.muted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            NovaButton.primary(
              label: 'Enregistrer les modifications',
              busy: _busy,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            NovaButton.ghost(
              label: 'Changer le mot de passe',
              icon: Icons.lock_reset_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed(RouteNames.changePassword),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round avatar with a camera badge; shows a spinner while uploading.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatarUrl,
    required this.initials,
    required this.uploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final String initials;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.deepInk,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          if (uploading)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.ink.withValues(alpha: .55),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: AppColors.lime,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: AppColors.lime,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.4),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 16, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
