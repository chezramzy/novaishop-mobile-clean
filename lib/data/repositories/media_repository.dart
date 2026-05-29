import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_config.dart';
import '../models/media_asset.dart';
import 'repository_error.dart';

/// Media uploads (`/v1/uploads/sign`). Token-dependent. Provides the signed
/// upload target and a helper to perform the actual binary PUT.
class MediaRepository {
  MediaRepository({
    required String? accessToken,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _accessToken = accessToken,
        _hasToken = accessToken != null && accessToken.isNotEmpty;

  final http.Client _httpClient;
  final String? _accessToken;
  final bool _hasToken;

  void _requireToken() {
    if (!_hasToken) {
      throw RepositoryException(
        'Votre session a expiré. Reconnectez-vous pour envoyer un fichier.',
      );
    }
  }

  /// Requests a signed upload target.
  Future<UploadSignedTarget> signUpload({
    required String bucket,
    required String fileName,
    required String contentType,
    required String kind,
    String? documentType,
  }) async {
    _requireToken();
    try {
      final resolvedBucket = _resolveBucket(bucket);
      final objectKey = _objectKey(
        fileName: fileName,
        contentType: contentType,
        kind: documentType == null ? kind : '$kind-$documentType',
      );
      final asset = _asset(
        bucket: resolvedBucket,
        objectKey: objectKey,
        fileName: fileName,
        contentType: contentType,
        kind: kind,
        status: 'pending_upload',
      );
      return UploadSignedTarget(
        asset: asset,
        method: 'PUT',
        uploadUrl: 'supabase://$resolvedBucket/$objectKey',
        headers: const {},
        publicUrl: asset.publicUrl,
        expiresAt: DateTime.now()
            .add(const Duration(minutes: 15))
            .toUtc()
            .toIso8601String(),
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Uploads [bytes] to a previously signed [target] via HTTP PUT.
  Future<void> uploadBytes(
    UploadSignedTarget target,
    Uint8List bytes,
  ) async {
    try {
      if (target.uploadUrl.startsWith('supabase://')) {
        final destination = _parseSupabaseTarget(target.uploadUrl);
        await _bucket(destination.bucket).uploadBinary(
          destination.objectKey,
          bytes,
          fileOptions: FileOptions(
            contentType: target.asset.contentType,
            upsert: false,
          ),
        );
        return;
      }

      final response = await _httpClient.put(
        Uri.parse(target.uploadUrl),
        headers: target.headers,
        body: bytes,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RepositoryException(
          "L'envoi du fichier a échoué. Réessayez.",
          statusCode: response.statusCode,
        );
      }
    } catch (error) {
      if (error is RepositoryException) rethrow;
      throw RepositoryException(
        'Connexion au serveur impossible. Vérifiez votre réseau.',
      );
    }
  }

  /// Convenience: signs an upload then performs the PUT, returning the
  /// resulting [MediaAsset] (with its public URL when available).
  Future<MediaAsset> uploadImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    String kind = 'listing_image',
    String bucket = SupabaseConfig.mediaBucket,
  }) async {
    _requireToken();
    try {
      final resolvedBucket = _resolveBucket(bucket);
      final objectKey = _objectKey(
        fileName: fileName,
        contentType: contentType,
        kind: kind,
      );
      await _bucket(resolvedBucket).uploadBinary(
        objectKey,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );
      return _asset(
        bucket: resolvedBucket,
        objectKey: objectKey,
        fileName: fileName,
        contentType: contentType,
        kind: kind,
        status: 'uploaded',
      );
    } catch (error) {
      throw RepositoryErrorMapper.wrap(error);
    }
  }

  /// Signs, uploads and returns the public URL of an image stored in the
  /// public bucket — used for avatars and listing photos.
  Future<String> uploadPublicImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final asset = await uploadImage(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    final url = asset.publicUrl ?? '';
    if (url.isEmpty) {
      throw RepositoryException(
        "L'image a été envoyée mais son lien est indisponible.",
      );
    }
    return url;
  }

  StorageFileApi _bucket(String bucket) {
    return Supabase.instance.client.storage.from(bucket);
  }

  String _resolveBucket(String bucket) {
    if (bucket.isEmpty || bucket == 'public-media' || bucket == 'private-kyc') {
      return SupabaseConfig.mediaBucket;
    }
    return bucket;
  }

  String _ownerUserId() {
    final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;
    if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
      return supabaseUserId;
    }
    final token = _accessToken ?? '';
    if (token.startsWith('local:')) return token.substring('local:'.length);
    throw RepositoryException('Reconnectez-vous pour envoyer un fichier.');
  }

  String _objectKey({
    required String fileName,
    required String contentType,
    required String kind,
  }) {
    final owner = _safeSegment(_ownerUserId(), fallback: 'anonymous');
    final folder = _safeSegment(kind, fallback: 'media');
    final safeName = _safeFileName(fileName, contentType);
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'uploads/$owner/$folder/$stamp-$safeName';
  }

  MediaAsset _asset({
    required String bucket,
    required String objectKey,
    required String fileName,
    required String contentType,
    required String kind,
    required String status,
  }) {
    final now = DateTime.now().toUtc();
    return MediaAsset(
      id: 'media-${now.microsecondsSinceEpoch}',
      ownerUserId: _ownerUserId(),
      bucket: bucket,
      objectKey: objectKey,
      fileName: fileName,
      contentType: contentType,
      kind: kind,
      status: status,
      publicUrl: _bucket(bucket).getPublicUrl(objectKey),
      thumbnails: const [],
      createdAt: now.toIso8601String(),
    );
  }

  String _safeFileName(String fileName, String contentType) {
    final raw = fileName.trim().isEmpty ? 'image' : fileName.trim();
    final dot = raw.lastIndexOf('.');
    final name = dot > 0 ? raw.substring(0, dot) : raw;
    final extension =
        dot > 0 ? raw.substring(dot + 1) : _extension(contentType);
    final safeBase = _safeSegment(name, fallback: 'image');
    final safeExtension = _safeSegment(extension, fallback: 'jpg');
    return '$safeBase.$safeExtension';
  }

  String _safeSegment(String value, {required String fallback}) {
    final safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');
    return safe.isEmpty ? fallback : safe;
  }

  String _extension(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }

  _SupabaseUploadTarget _parseSupabaseTarget(String uploadUrl) {
    final uri = Uri.parse(uploadUrl);
    final bucket = uri.host;
    final objectKey = uri.pathSegments.join('/');
    if (bucket.isEmpty || objectKey.isEmpty) {
      throw RepositoryException(
          "La destination d'envoi du fichier est invalide.");
    }
    return _SupabaseUploadTarget(bucket, objectKey);
  }
}

class _SupabaseUploadTarget {
  const _SupabaseUploadTarget(this.bucket, this.objectKey);

  final String bucket;
  final String objectKey;
}
