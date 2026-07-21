import '../../domain/entities/contact.dart';

class ContactModel extends Contact {
  const ContactModel({
    required super.id,
    required super.firstName,
    super.lastName,
    super.email,
    super.phone,
    super.jobTitle,
    required super.accountId,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      jobTitle: json['job_title'] as String?,
      accountId: json['account_id'] as int,
    );
  }

  /// Request body for `POST /contacts`.
  static Map<String, dynamic> toCreateJson({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    required int accountId,
  }) {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'job_title': jobTitle,
      'account_id': accountId,
    };
  }

  /// Request body for `PATCH /contacts/{id}` — account_id cannot be
  /// reassigned per the API doc, so it's intentionally not accepted here.
  static Map<String, dynamic> toUpdateJson({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
  }) {
    return {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (jobTitle != null) 'job_title': jobTitle,
    };
  }
}
