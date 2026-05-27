import '../models/ai_models.dart';

class AiRepository {
  AiRepository({required String? accessToken});

  Future<AiListingSuggestion> generateListingFromImage({
    required String imageUrl,
    String? sellerPrompt,
  }) async {
    return AiListingSuggestion(
      suggestedTitle: 'Nouveau produit',
      suggestedDescription:
          sellerPrompt?.trim().isNotEmpty == true ? sellerPrompt!.trim() : '',
      categoryType: 'product',
      confidence: 0,
      extractedAttributes: const {},
      moderationHints: const [
        'Suggestion locale: completez les champs avant publication.',
      ],
    );
  }

  Future<AiChatResponse> chat({
    required String role,
    required String message,
  }) async {
    return const AiChatResponse(
      answer:
          "Mode local actif. Je peux vous guider dans l'app, mais l'assistant intelligent sera branche plus tard.",
      scope: 'faq',
      sources: [],
    );
  }
}
