import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/repository_error.dart';
import '../../data/repositories/review_repository.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'review_widgets.dart';

class WriteReviewArgs {
  const WriteReviewArgs({
    required this.targetId,
    required this.targetName,
    this.isVendor = false,
  });

  final String targetId;
  final String targetName;

  /// Legacy compatibility flag. Partner reviews are blocked publicly.
  final bool isVendor;
}

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({required this.args, super.key});

  final WriteReviewArgs args;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      _toast('Connectez-vous pour publier un avis.');
      return;
    }
    if (widget.args.isVendor) {
      _toast('Les avis partenaires ne sont pas exposes dans NovaShop.');
      return;
    }
    if (_rating == 0) {
      _toast('Selectionnez une note avant de publier.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final repository = ReviewRepository(accessToken: auth.accessToken);
    try {
      await repository.createListingReview(
        listingId: widget.args.targetId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      _toast('Merci ! Votre avis a ete publie.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _toast(
        error is RepositoryException
            ? error.message
            : "Impossible de publier l'avis pour le moment.",
      );
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            const ScreenHeader(title: 'Donner mon avis'),
            const SizedBox(height: 24),
            NovaCard(
              child: Column(
                children: [
                  Text(
                    'Comment evaluez-vous ce produit ?',
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.args.targetName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  StarSelector(
                    value: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ratingLabel(_rating),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: _rating == 0
                          ? AppColors.muted
                          : context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ).fadeSlideIn(),
            const SizedBox(height: 18),
            NovaTextField(
              controller: _commentController,
              label: 'Votre commentaire',
              hint: 'Partagez votre experience en quelques mots...',
              maxLines: 5,
              minLines: 4,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 3) {
                  return 'Ecrivez au moins 3 caracteres.';
                }
                return null;
              },
            ).fadeSlideIn(delay: AppMotion.fast),
            const SizedBox(height: 12),
            NovaButton.primary(
              label: 'Publier mon avis',
              icon: Icons.send_rounded,
              busy: _submitting,
              onPressed: _submit,
            ).fadeSlideIn(delay: AppMotion.normal),
          ],
        ),
      ),
    );
  }
}

Future<bool> openWriteReviewSheet(
  BuildContext context, {
  required String targetId,
  required String targetName,
  bool isVendor = false,
}) async {
  final result = await showNovaSheet<bool>(
    context: context,
    builder: (_) => _WriteReviewSheetBody(
      args: WriteReviewArgs(
        targetId: targetId,
        targetName: targetName,
        isVendor: isVendor,
      ),
    ),
  );
  return result ?? false;
}

class _WriteReviewSheetBody extends StatefulWidget {
  const _WriteReviewSheetBody({required this.args});

  final WriteReviewArgs args;

  @override
  State<_WriteReviewSheetBody> createState() => _WriteReviewSheetBodyState();
}

class _WriteReviewSheetBodyState extends State<_WriteReviewSheetBody> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      setState(() => _error = 'Connectez-vous pour publier un avis.');
      return;
    }
    if (widget.args.isVendor) {
      setState(
        () =>
            _error = 'Les avis partenaires ne sont pas exposes dans NovaShop.',
      );
      return;
    }
    if (_rating == 0) {
      setState(() => _error = 'Selectionnez une note.');
      return;
    }
    if (_commentController.text.trim().length < 3) {
      setState(() => _error = 'Ecrivez au moins 3 caracteres.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final repository = ReviewRepository(accessToken: auth.accessToken);
    try {
      await repository.createListingReview(
        listingId: widget.args.targetId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is RepositoryException
            ? error.message
            : "Impossible de publier l'avis.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Donner mon avis',
          style: AppTypography.title,
        ),
        const SizedBox(height: 4),
        Text(
          widget.args.targetName,
          style: AppTypography.caption,
        ),
        const SizedBox(height: 18),
        StarSelector(
          value: _rating,
          size: 36,
          onChanged: (value) => setState(() => _rating = value),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            ratingLabel(_rating),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 16),
        NovaTextField(
          controller: _commentController,
          label: 'Votre commentaire',
          hint: 'Partagez votre experience...',
          maxLines: 4,
          minLines: 3,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
        const SizedBox(height: 12),
        NovaButton.primary(
          label: 'Publier',
          icon: Icons.send_rounded,
          busy: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
