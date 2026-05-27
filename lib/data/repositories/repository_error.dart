import 'dart:convert';

import '../../core/api/api_exception.dart';

/// Raised by repositories when an API call fails, carrying a French,
/// user-facing message.
class RepositoryException implements Exception {
  RepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Maps API and transport failures to French messages. Every repository
/// routes its `catch` blocks through this so error copy stays consistent.
class RepositoryErrorMapper {
  const RepositoryErrorMapper._();

  /// Translates an [ApiException] into a friendly French message.
  static String friendly(ApiException error) {
    final parsed = messageFromBody(error.message);
    switch (error.statusCode) {
      case 401:
        return 'Votre session a expiré. Reconnectez-vous pour continuer.';
      case 403:
        return parsed ?? "Vous n'avez pas accès à cette ressource.";
      case 404:
        return parsed ?? 'Élément introuvable.';
      case 409:
        return parsed ??
            'Cette action entre en conflit avec une donnée existante.';
      case 422:
      case 400:
        return parsed ?? 'Données invalides. Vérifiez le formulaire.';
      case 429:
        return 'Trop de requêtes. Patientez un instant avant de réessayer.';
      default:
        return parsed ?? 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  /// Wraps any thrown error into a [RepositoryException] with French copy.
  static RepositoryException wrap(Object error) {
    if (error is RepositoryException) return error;
    if (error is ApiException) {
      return RepositoryException(
        friendly(error),
        statusCode: error.statusCode,
      );
    }
    return RepositoryException(
      'Connexion au serveur impossible. Vérifiez votre réseau.',
    );
  }

  /// Extracts a clean message from a JSON error body, if present.
  static String? messageFromBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        final message = (decoded['message'] as String).trim();
        if (message.isEmpty) return null;
        if (message.startsWith('[') || message.startsWith('{')) {
          return 'Données invalides. Vérifiez le formulaire.';
        }
        return message;
      }
    } catch (_) {
      // Fall through.
    }
    return null;
  }
}
