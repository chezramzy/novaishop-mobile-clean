import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/ai_models.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/repository_error.dart';
import '../../design/design_system.dart';
import '../auth/auth_controller.dart';
import 'add_product_screen.dart';
import 'widgets/seller_upload.dart';
import 'widgets/seller_widgets.dart';

/// AI listing generator: the seller picks a product photo, it is uploaded
/// via [MediaRepository], then [AiRepository.generateListingFromImage]
/// produces a suggested title, description and attributes. The seller can
/// then push the suggestion straight into the add-product form.
class AiListingGeneratorScreen extends StatefulWidget {
  const AiListingGeneratorScreen({required this.shopId, super.key});

  final String shopId;

  @override
  State<AiListingGeneratorScreen> createState() =>
      _AiListingGeneratorScreenState();
}

enum _GeneratorStep { idle, uploading, generating, done }

class _AiListingGeneratorScreenState extends State<AiListingGeneratorScreen> {
  final _promptController = TextEditingController();

  _GeneratorStep _step = _GeneratorStep.idle;
  Uint8List? _pickedBytes;
  String? _imageUrl;
  AiListingSuggestion? _suggestion;
  String? _error;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickAndGenerate() async {
    if (_step == _GeneratorStep.uploading ||
        _step == _GeneratorStep.generating) {
      return;
    }
    final token = context.read<AuthController>().accessToken;
    final picked = await SellerUploadPicker.pickGalleryImage();
    if (picked == null) return;

    setState(() {
      _pickedBytes = picked.bytes;
      _suggestion = null;
      _error = null;
      _step = _GeneratorStep.uploading;
    });

    try {
      final media = MediaRepository(accessToken: token);
      final asset = await media.uploadImage(
        bytes: picked.bytes,
        fileName: picked.fileName,
        contentType: picked.contentType,
      );
      final url = asset.publicUrl;
      if (url == null || url.isEmpty) {
        throw RepositoryException(
          "L'image a été envoyée mais aucune URL n'a été renvoyée.",
        );
      }
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _step = _GeneratorStep.generating;
      });

      final ai = AiRepository(accessToken: token);
      final suggestion = await ai.generateListingFromImage(
        imageUrl: url,
        sellerPrompt: _promptController.text.trim().isEmpty
            ? null
            : _promptController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _suggestion = suggestion;
        _step = _GeneratorStep.done;
      });
    } on RepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _step = _GeneratorStep.idle;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'La génération a échoué. Réessayez avec une autre photo.';
          _step = _GeneratorStep.idle;
        });
      }
    }
  }

  Future<void> _useSuggestion() async {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    final created = await Navigator.of(context).push<bool>(
      AppPageRoute.sharedAxis(
        AddProductScreen(
          shopId: widget.shopId,
          aiSuggestion: suggestion,
          prefillImageUrl: _imageUrl,
        ),
      ),
    );
    if (created == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SoftGradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: StaggeredEntrance.all([
          const ScreenHeader(title: 'Fiche produit IA'),
          const SizedBox(height: AppSpacing.md),
          const SellerInfoBanner(
            icon: Icons.auto_awesome_outlined,
            message: 'Choisissez une photo de votre produit. L\'assistant IA '
                'rédige automatiquement le titre, la description et les '
                'caractéristiques.',
          ),
          const SizedBox(height: AppSpacing.md),
          SellerImagePreview(
            bytes: _pickedBytes,
            url: _imageUrl,
            placeholderLabel: 'Aucune photo sélectionnée',
          ),
          const SizedBox(height: AppSpacing.sm),
          NovaTextField(
            controller: _promptController,
            label: 'Précisions (facultatif)',
            hint: 'Ex. marque, état, matière, points forts…',
            icon: Icons.tips_and_updates_outlined,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          NovaButton.primary(
            label: _suggestion == null
                ? 'Générer la fiche'
                : 'Générer une autre fiche',
            icon: Icons.auto_awesome_rounded,
            busy: _step == _GeneratorStep.uploading ||
                _step == _GeneratorStep.generating,
            onPressed: _pickAndGenerate,
          ),
          if (_step == _GeneratorStep.uploading ||
              _step == _GeneratorStep.generating) ...[
            const SizedBox(height: AppSpacing.md),
            _ProgressNote(
              label: _step == _GeneratorStep.uploading
                  ? 'Envoi de la photo…'
                  : 'Analyse de la photo par l\'IA…',
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorNote(message: _error!),
          ],
          if (_suggestion != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _SuggestionCard(suggestion: _suggestion!),
            const SizedBox(height: AppSpacing.md),
            NovaButton.primary(
              label: 'Utiliser cette fiche',
              icon: Icons.arrow_forward_rounded,
              onPressed: _useSuggestion,
            ),
          ],
        ]),
      ),
    );
  }
}

class _ProgressNote extends StatelessWidget {
  const _ProgressNote({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.blush,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: context.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final AiListingSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final confidence = (suggestion.confidence * 100).round();
    return SellerPanel(
      title: 'Proposition de l\'IA',
      icon: Icons.auto_awesome_outlined,
      trailing: NovaBadge(
        label: 'Fiabilité $confidence %',
        tone: confidence >= 70
            ? NovaBadgeTone.success
            : confidence >= 40
                ? NovaBadgeTone.warning
                : NovaBadgeTone.danger,
        dense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Titre',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suggestion.suggestedTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Description',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suggestion.suggestedDescription,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
          if (suggestion.extractedAttributes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Caractéristiques détectées',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in suggestion.extractedAttributes.entries)
                  NovaBadge(
                    label: '${entry.key} : ${entry.value}',
                    dense: true,
                  ),
              ],
            ),
          ],
          if (suggestion.moderationHints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.butter,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'À vérifier avant publication',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  for (final hint in suggestion.moderationHints)
                    Text(
                      '• $hint',
                      style: const TextStyle(fontSize: 11.5, height: 1.4),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
