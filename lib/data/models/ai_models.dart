import 'json_utils.dart';

/// An AI-generated listing suggestion (`AiListingSuggestion` interface),
/// returned by `POST /v1/ai/listing-from-image`.
class AiListingSuggestion {
  const AiListingSuggestion({
    required this.suggestedTitle,
    required this.suggestedDescription,
    required this.categoryType,
    required this.confidence,
    required this.extractedAttributes,
    required this.moderationHints,
  });

  final String suggestedTitle;
  final String suggestedDescription;

  /// `product`, `service` or `property`.
  final String categoryType;

  /// Confidence score between 0 and 1.
  final double confidence;
  final Map<String, String> extractedAttributes;
  final List<String> moderationHints;

  factory AiListingSuggestion.fromJson(Map<String, dynamic> json) {
    final rawAttributes = Json.obj(json['extractedAttributes']);
    return AiListingSuggestion(
      suggestedTitle: Json.str(json['suggestedTitle']),
      suggestedDescription: Json.str(json['suggestedDescription']),
      categoryType: Json.str(json['categoryType'], 'product'),
      confidence: Json.dbl(json['confidence']),
      extractedAttributes:
          rawAttributes.map((key, value) => MapEntry(key, value.toString())),
      moderationHints: Json.stringList(json['moderationHints']),
    );
  }
}

/// An AI assistant chat reply (`AiChatResponse` interface), returned by
/// `POST /v1/ai/chat`.
class AiChatResponse {
  const AiChatResponse({
    required this.answer,
    required this.scope,
    required this.sources,
  });

  final String answer;

  /// `faq`, `seller_assistant` or `order_status`.
  final String scope;
  final List<String> sources;

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      answer: Json.str(json['answer']),
      scope: Json.str(json['scope'], 'faq'),
      sources: Json.stringList(json['sources']),
    );
  }
}
