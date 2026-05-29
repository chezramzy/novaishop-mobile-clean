import 'dart:typed_data';

import 'json_utils.dart';

class PartnerApplicationImage {
  const PartnerApplicationImage({
    required this.fileName,
    required this.contentType,
    this.bytes,
    this.objectKey,
    this.publicUrl,
    this.legacyDataUrl,
  });

  final Uint8List? bytes;
  final String fileName;
  final String contentType;
  final String? objectKey;
  final String? publicUrl;
  final String? legacyDataUrl;

  String get displayUrl => publicUrl ?? legacyDataUrl ?? '';

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'contentType': contentType,
      if (objectKey != null) 'objectKey': objectKey,
      if (publicUrl != null) 'publicUrl': publicUrl,
    };
  }

  factory PartnerApplicationImage.fromJson(Map<String, dynamic> json) {
    return PartnerApplicationImage(
      fileName: Json.str(json['fileName'] ?? json['file_name']),
      contentType: Json.str(json['contentType'] ?? json['content_type']),
      objectKey: Json.strOrNull(json['objectKey'] ?? json['object_key']),
      publicUrl: Json.strOrNull(json['publicUrl'] ?? json['public_url']),
      legacyDataUrl: Json.strOrNull(json['dataUrl'] ?? json['data_url']),
    );
  }
}

class PartnerApplication {
  const PartnerApplication({
    required this.id,
    required this.whatsapp,
    required this.productDescription,
    required this.images,
    required this.applicantUserId,
    required this.applicantEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.adminNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String whatsapp;
  final String productDescription;
  final List<PartnerApplicationImage> images;
  final String applicantUserId;
  final String applicantEmail;
  final String status;
  final String? adminNotes;
  final String createdAt;
  final String updatedAt;
  final String? reviewedAt;
  final String? reviewedBy;

  bool get isActive =>
      status == 'new' ||
      status == 'reviewing' ||
      status == 'approved' ||
      status == 'rejected';

  factory PartnerApplication.fromJson(Map<String, dynamic> json) {
    return PartnerApplication(
      id: Json.str(json['id']),
      whatsapp: Json.str(json['whatsapp']),
      productDescription:
          Json.str(json['productDescription'] ?? json['product_description']),
      images: Json.list(
        json['productImages'] ?? json['product_images'],
        PartnerApplicationImage.fromJson,
      ),
      applicantUserId:
          Json.str(json['applicantUserId'] ?? json['applicant_user_id']),
      applicantEmail:
          Json.str(json['applicantEmail'] ?? json['applicant_email']),
      status: Json.str(json['status'], 'new'),
      adminNotes: Json.strOrNull(json['adminNotes'] ?? json['admin_notes']),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
      updatedAt: Json.str(json['updatedAt'] ?? json['updated_at']),
      reviewedAt: Json.strOrNull(json['reviewedAt'] ?? json['reviewed_at']),
      reviewedBy: Json.strOrNull(json['reviewedBy'] ?? json['reviewed_by']),
    );
  }
}
