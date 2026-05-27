import 'json_utils.dart';

/// A seller's vendor profile (`VendorProfile` interface).
class VendorProfile {
  const VendorProfile({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.kycStatus,
    required this.payoutAccountStatus,
    required this.commissionRate,
    required this.documentsComplete,
    required this.createdAt,
    this.sellerType,
    this.legalFullName,
  });

  final String id;
  final String userId;
  final String shopId;

  /// One of: `draft`, `submitted`, `under_review`, `approved`, `rejected`.
  final String kycStatus;

  /// One of: `pending`, `verified`, `restricted`.
  final String payoutAccountStatus;
  final double commissionRate;
  final bool documentsComplete;

  /// One of: `individual`, `registered_business`, `agency`.
  final String? sellerType;
  final String? legalFullName;
  final String createdAt;

  bool get isApproved => kycStatus == 'approved';

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: Json.str(json['id']),
      userId: Json.str(json['userId']),
      shopId: Json.str(json['shopId']),
      kycStatus: Json.str(json['kycStatus'], 'draft'),
      payoutAccountStatus: Json.str(json['payoutAccountStatus'], 'pending'),
      commissionRate: Json.dbl(json['commissionRate']),
      documentsComplete: Json.boolean(json['documentsComplete']),
      sellerType: Json.strOrNull(json['sellerType']),
      legalFullName: Json.strOrNull(json['legalFullName']),
      createdAt: Json.str(json['createdAt']),
    );
  }
}
