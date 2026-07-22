import 'package:equatable/equatable.dart';

/// A contact person — mirrors the backend's `AccountContactRead` shape (see
/// `GET/POST /accounts/{id}/contacts`). Contacts are many-to-many with
/// accounts via the `contact_accounts` join table, and `isPrimary` is
/// per-account (a contact can be primary for one account, not another).
///
/// The account-scoped read shape carries no `account_id` field, so
/// [accountId] is nullable and populated only when a caller knows the context
/// (e.g. it navigated from a specific account).
class Contact extends Equatable {
  final int id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final String? jobTitle;
  final String? linkedinUrl;
  final bool isPrimary;
  final int? accountId;

  const Contact({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.alternatePhone,
    this.jobTitle,
    this.linkedinUrl,
    this.isPrimary = false,
    this.accountId,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  Contact copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? jobTitle,
    String? linkedinUrl,
    bool? isPrimary,
    int? accountId,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      jobTitle: jobTitle ?? this.jobTitle,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    alternatePhone,
    jobTitle,
    linkedinUrl,
    isPrimary,
    accountId,
  ];
}
