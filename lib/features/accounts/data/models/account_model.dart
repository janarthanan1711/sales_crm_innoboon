import '../../domain/entities/account.dart';
import '../../domain/entities/contact.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.companyName,
    required super.domain,
    required super.industry,
    required super.tier,
    required super.primaryOwner,
    required super.description,
    super.contacts,
    super.activeDealsCount,
    required super.createdAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    // Parse contacts if available
    final rawContacts = json['contacts'] as List<dynamic>?;
    final parsedContacts = rawContacts?.map((c) {
      return Contact(
        id: c['id']?.toString() ?? '',
        name: c['name'] ?? '',
        email: c['email'] ?? '',
        phone: c['phone'] ?? '',
        role: c['role'] ?? '',
        accountId: json['id']?.toString() ?? '',
      );
    }).toList();

    return AccountModel(
      id: json['id']?.toString() ?? '',
      companyName: json['company'] as String? ?? 'Unknown Company',
      domain: json['domain'] as String? ?? '',
      industry: json['industry'] as String? ?? 'Unknown',
      tier: json['tier'] as String? ?? 'standard',
      // If the API returns owner_name we use it, otherwise fallback to owner_id
      primaryOwner: json['owner_name'] as String? ?? 
                    (json['owner_id'] != null ? 'Owner ${json['owner_id']}' : 'Unassigned'),
      description: json['description'] as String? ?? '',
      contacts: parsedContacts ?? [],
      activeDealsCount: json['active_deals_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company': companyName,
      'domain': domain,
      'industry': industry,
      'tier': tier,
      'description': description,
    };
  }
}
