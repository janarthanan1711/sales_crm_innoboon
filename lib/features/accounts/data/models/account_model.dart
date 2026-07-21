import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.companyName,
    super.domain,
    required super.tier,
    super.ownerId,
    required super.primaryOwner,
    super.industry,
    super.city,
    super.description,
    super.linkedinUrl,
    super.sourceLeadId,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final ownerId = json['owner_id'] as int?;
    return AccountModel(
      id: '${json['id']}',
      companyName: json['company'] as String? ?? 'Unknown Company',
      domain: json['domain'] as String?,
      tier: json['tier'] as String? ?? 'standard',
      ownerId: ownerId,
      primaryOwner: ownerId != null ? 'Owner $ownerId' : 'Unassigned',
      industry: json['industry'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String? ?? '',
      linkedinUrl: json['linkedin_url'] as String?,
      sourceLeadId: json['source_lead_id'] as int?,
    );
  }

  /// Request body shared by `POST /accounts` and `PATCH /accounts/{id}`.
  static Map<String, dynamic> toJson({
    required String company,
    String? domain,
    required String tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
  }) {
    return {
      'company': company,
      'domain': domain,
      'tier': tier,
      'owner_id': ownerId,
      'industry': industry,
      'city': city,
      'description': description,
      'linkedin_url': linkedinUrl,
    };
  }
}
