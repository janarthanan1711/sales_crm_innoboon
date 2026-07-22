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
    super.contactCount,
    super.dealCount,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    final ownerId = json['owner_id'] as int?;
    final ownerName = json['owner_name'] as String?;
    return AccountModel(
      id: '${json['id']}',
      companyName: json['company'] as String? ?? 'Unknown Company',
      domain: json['domain'] as String?,
      tier: json['tier'] as String? ?? 'standard',
      ownerId: ownerId,
      primaryOwner: (ownerName != null && ownerName.isNotEmpty)
          ? ownerName
          : (ownerId != null ? 'Owner $ownerId' : 'Unassigned'),
      industry: json['industry'] as String?,
      city: json['city'] as String?,
      description: json['description'] as String? ?? '',
      linkedinUrl: json['linkedin_url'] as String?,
      sourceLeadId: json['source_lead_id'] as int?,
      contactCount: json['contact_count'] as int? ?? 0,
      dealCount: json['deal_count'] as int? ?? 0,
    );
  }

  /// Request body for `POST /accounts`. Optionally embeds a `contacts[]`
  /// array — per the API, `first_name` is required only on `contacts[0]`;
  /// later contacts omit it to inherit the first's name.
  static Map<String, dynamic> toCreateJson({
    required String company,
    String? domain,
    required String tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
    List<AccountContactDraft>? contacts,
  }) {
    final body = <String, dynamic>{
      'company': company,
      'domain': domain,
      'tier': tier,
      'owner_id': ownerId,
      'industry': industry,
      'city': city,
      'description': description,
      'linkedin_url': linkedinUrl,
    };
    if (contacts != null && contacts.isNotEmpty) {
      body['contacts'] = contacts
          .map((c) => <String, dynamic>{
                if (c.firstName != null && c.firstName!.isNotEmpty)
                  'first_name': c.firstName,
                if (c.lastName != null && c.lastName!.isNotEmpty)
                  'last_name': c.lastName,
                if (c.email != null && c.email!.isNotEmpty) 'email': c.email,
                if (c.phone != null && c.phone!.isNotEmpty) 'phone': c.phone,
                if (c.jobTitle != null && c.jobTitle!.isNotEmpty)
                  'job_title': c.jobTitle,
              })
          .toList();
    }
    return body;
  }
}
