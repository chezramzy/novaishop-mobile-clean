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
      userId: Json.str(json['userId'] ?? json['user_id']),
      shopId: Json.str(json['shopId'] ?? json['shop_id']),
      kycStatus: Json.str(json['kycStatus'] ?? json['kyc_status'], 'draft'),
      payoutAccountStatus: Json.str(
        json['payoutAccountStatus'] ?? json['payout_account_status'],
        'pending',
      ),
      commissionRate:
          Json.dbl(json['commissionRate'] ?? json['commission_rate']),
      documentsComplete: Json.boolean(
        json['documentsComplete'] ?? json['documents_complete'],
      ),
      sellerType: Json.strOrNull(json['sellerType'] ?? json['seller_type']),
      legalFullName:
          Json.strOrNull(json['legalFullName'] ?? json['legal_name']),
      createdAt: Json.str(json['createdAt'] ?? json['created_at']),
    );
  }
}
