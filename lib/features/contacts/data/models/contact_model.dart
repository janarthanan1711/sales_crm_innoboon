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
      // Account-scoped read shape omits account_id; present only elsewhere.
      accountId: json['account_id'] as int?,
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
      if (contactId != null) 'contact_id': contactId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (alternatePhone != null) 'alternate_phone': alternatePhone,
      if (jobTitle != null) 'job_title': jobTitle,
      if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
      if (isPrimary != null) 'is_primary': isPrimary,
    };
  }
}
