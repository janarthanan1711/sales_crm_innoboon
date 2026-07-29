import '../../domain/entities/contact.dart';

class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.firstName,
    super.lastName,
    super.email,
    super.phone,
    super.alternatePhone,
    super.jobTitle,
    super.linkedinUrl,
    super.isPrimary,
    super.accountId,
    super.accountName,
    super.ownerId,
    super.ownerName,
    super.tier,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      alternatePhone: json['alternate_phone'] as String?,
      jobTitle: json['job_title'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      // Present on the list / overview shapes; absent (⇒ null) on the bare
      // `GET /contacts/{id}` and account-scoped read shapes.
      accountId: json['account_id'] as int?,
      accountName: json['account_name'] as String?,
      ownerId: json['owner_id'] as int?,
      ownerName: json['owner_name'] as String?,
      tier: json['tier'] as String?,
    );
  }

  /// Parses `GET /contacts/{id}/overview` — the contact fields (incl. derived
  /// representative-account fields) plus related-record counts.
  static ContactOverview overviewFromJson(Map<String, dynamic> json) {
    return ContactOverview(
      contact: ContactModel.fromJson(json),
      dealCount: json['deal_count'] as int? ?? 0,
      taskCount: json['task_count'] as int?,
      logCount: json['log_count'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      about: json['about'] as String?,
      lastActivity: json['last_activity'] != null
          ? DateTime.tryParse(json['last_activity'] as String)
          : null,
    );
  }

  /// Parses one row of `GET /contacts/{id}/deals`.
  static ContactDeal dealFromJson(Map<String, dynamic> json) {
    return ContactDeal(
      id: json['id'] as int,
      dealName: json['deal_name'] as String? ?? json['name'] as String? ?? '—',
      accountId: json['account_id'] as int?,
      value: (json['value'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String?,
      stageId: json['stage_id'] as int?,
      tier: json['tier'] as String?,
      ownerId: json['owner_id'] as int?,
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.tryParse(json['expected_close_date'] as String)
          : null,
    );
  }

  /// Request body for `POST /accounts/{account_id}/contacts` — create OR
  /// update (the backend dispatches on the presence of `contact_id`). Only
  /// non-null fields are sent, so a partial update touches only what changed.
  static Map<String, dynamic> toUpsertJson({
    int? contactId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? jobTitle,
    String? linkedinUrl,
    bool? isPrimary,
  }) {
    return {
      'contact_id': ?contactId,
      'first_name': ?firstName,
      'last_name': ?lastName,
      'email': ?email,
      'phone': ?phone,
      'alternate_phone': ?alternatePhone,
      'job_title': ?jobTitle,
      'linkedin_url': ?linkedinUrl,
      'is_primary': ?isPrimary,
    };
  }
}
