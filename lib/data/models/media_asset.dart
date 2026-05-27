import 'json_utils.dart';

/// A generated thumbnail for a [MediaAsset].
class MediaThumbnail {
  const MediaThumbnail({
    required this.width,
    required this.height,
    required this.url,
    required this.format,
    required this.size,
  });

  final int width;
  final int height;
  final String url;
  final String format;
  final int size;

  factory MediaThumbnail.fromJson(Map<String, dynamic> json) {
    return MediaThumbnail(
      width: Json.integer(json['width']),
      height: Json.integer(json['height']),
      url: Json.str(json['url']),
      format: Json.str(json['format']),
      size: Json.integer(json['size']),
    );
  }
}

/// An uploaded media asset (`MediaAsset` interface).
class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.ownerUserId,
    required this.bucket,
    required this.objectKey,
    required this.fileName,
    required this.contentType,
    required this.kind,
    required this.status,
    required this.thumbnails,
    required this.createdAt,
    this.vendorId,
    this.publicUrl,
  });

  final String id;
  final String ownerUserId;
  final String? vendorId;

  /// `public-media` or `private-kyc`.
  final String bucket;
  final String objectKey;
  final String fileName;
  final String contentType;

  /// `listing_image` or `kyc_document`.
  final String kind;

  /// `pending_upload` or `uploaded`.
  final String status;
  final String? publicUrl;
  final List<MediaThumbnail> thumbnails;
  final String createdAt;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: Json.str(json['id']),
      ownerUserId: Json.str(json['ownerUserId']),
      vendorId: Json.strOrNull(json['vendorId']),
      bucket: Json.str(json['bucket'], 'public-media'),
      objectKey: Json.str(json['objectKey']),
      fileName: Json.str(json['fileName']),
      contentType: Json.str(json['contentType']),
      kind: Json.str(json['kind'], 'listing_image'),
      status: Json.str(json['status'], 'pending_upload'),
      publicUrl: Json.strOrNull(json['publicUrl']),
      thumbnails: Json.list(json['thumbnails'], MediaThumbnail.fromJson),
      createdAt: Json.str(json['createdAt']),
    );
  }
}

/// A signed upload target (`UploadSignedTarget` interface), returned by
/// `POST /v1/uploads/sign`.
class UploadSignedTarget {
  const UploadSignedTarget({
    required this.asset,
    required this.method,
    required this.uploadUrl,
    required this.headers,
    required this.expiresAt,
    this.publicUrl,
  });

  final MediaAsset asset;

  /// Always `PUT`.
  final String method;
  final String uploadUrl;
  final Map<String, String> headers;
  final String? publicUrl;
  final String expiresAt;

  factory UploadSignedTarget.fromJson(Map<String, dynamic> json) {
    final rawHeaders = Json.obj(json['headers']);
    return UploadSignedTarget(
      asset: MediaAsset.fromJson(Json.obj(json['asset'])),
      method: Json.str(json['method'], 'PUT'),
      uploadUrl: Json.str(json['uploadUrl']),
      headers: rawHeaders.map((key, value) => MapEntry(key, value.toString())),
      publicUrl: Json.strOrNull(json['publicUrl']),
      expiresAt: Json.str(json['expiresAt']),
    );
  }
}
