import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../models/partner_application.dart';
import 'repository_error.dart';

class PartnerApplicationRepository {
  PartnerApplicationRepository({String? accessToken})
      : _accessToken = accessToken;

  final String? _accessToken;

  bool get _hasSupabaseSession =>
      Supabase.instance.client.auth.currentSession != null &&
      _accessToken != null &&
      _accessToken.isNotEmpty &&
      !_accessToken.startsWith('local:');

  void _requireSession() {
    if (!_hasSupabaseSession) {
      throw RepositoryException(
        'Reconnectez-vous avec un compte NovaShop pour envoyer cette demande.',
      );
    }
  }

  Future<PartnerApplication> submit({
    required String whatsapp,
    required String productDescription,
    required List<PartnerApplicationImage> images,
    String? applicantUserId,
    String? applicantEmail,
  }) async {
    _requireSession();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw RepositoryException('Session introuvable. Reconnectez-vous.');
    }
    final existing = await getLatestForUser(user.id);
    if (existing != null && existing.isActive) {
      throw RepositoryException(
        'Une demande partenaire existe deja pour ce compte.',
      );
    }
    if (images.length != 3) {
      throw RepositoryException('Ajoutez exactement 3 images de produits.');
    }

    try {
      final uploadedImages = <Map<String, dynamic>>[];
      for (var index = 0; index < images.length; index++) {
        uploadedImages.add(
          await _uploadApplicationImage(
            userId: user.id,
            image: images[index],
            index: index,
          ),
        );
      }

      final rows = await Supabase.instance.client
          .from('partner_applications')
          .insert({
            'whatsapp': whatsapp.trim(),
            'product_description': productDescription.trim(),
            'product_images': uploadedImages,
            'applicant_user_id': user.id,
            'applicant_email': user.email ?? applicantEmail,
            'source': 'mobile_app',
            'status': 'new',
          })
          .select()
          .limit(1);
      return PartnerApplication.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<PartnerApplication?> getLatestForUser(String userId) async {
    _requireSession();
    if (userId.trim().isEmpty) return null;
    try {
      final response = await Supabase.instance.client
          .from('partner_applications')
          .select()
          .eq('applicant_user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      if (response.isEmpty) return null;
      return PartnerApplication.fromJson(
        Map<String, dynamic>.from(response.first as Map),
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  Future<Map<String, dynamic>> _uploadApplicationImage({
    required String userId,
    required PartnerApplicationImage image,
    required int index,
  }) async {
    final bytes = image.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw RepositoryException('Image produit invalide.');
    }
    final objectKey =
        'uploads/$userId/partner_applications/${DateTime.now().toUtc().microsecondsSinceEpoch}-$index-${_safeFileName(image.fileName)}';
    await Supabase.instance.client.storage
        .from(SupabaseConfig.mediaBucket)
        .uploadBinary(
          objectKey,
          bytes,
          fileOptions: FileOptions(
            contentType: image.contentType,
            upsert: false,
          ),
        );
    return {
      'fileName': image.fileName,
      'contentType': image.contentType,
      'objectKey': objectKey,
      'publicUrl': Supabase.instance.client.storage
          .from(SupabaseConfig.mediaBucket)
          .getPublicUrl(objectKey),
    };
  }

  String _safeFileName(String fileName) {
    final safe = fileName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
    return safe.isEmpty ? 'produit.jpg' : safe;
  }
}
