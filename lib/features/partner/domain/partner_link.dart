/// Represents a row in the [partner_links] table.
class PartnerLink {
  const PartnerLink({
    required this.id,
    required this.userId,
    required this.partnerUserId,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;       // the woman's account
  final String partnerUserId;
  final String status;       // 'active' | 'revoked'
  final DateTime createdAt;

  bool get isActive => status == 'active';

  factory PartnerLink.fromJson(Map<String, dynamic> json) {
    return PartnerLink(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      partnerUserId: json['partner_user_id'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
