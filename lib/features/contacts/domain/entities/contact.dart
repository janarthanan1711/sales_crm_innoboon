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

  /// Derived from the contact's "representative" account link (see the
  /// Contacts API "Read this first" note): oldest primary link, else oldest
  /// link overall. Null when the contact has no linked account, or on the
  /// bare `GET /contacts/{id}` shape which omits them.
  final String? accountName;
  final int? ownerId;
  final String? ownerName;
  final String? tier;

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
    this.accountName,
    this.ownerId,
    this.ownerName,
    this.tier,
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
    String? accountName,
    int? ownerId,
    String? ownerName,
    String? tier,
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
      accountName: accountName ?? this.accountName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      tier: tier ?? this.tier,
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
    accountName,
    ownerId,
    ownerName,
    tier,
  ];
}

/// The Contact Detail "Overview" tab payload (`GET /contacts/{id}/overview`):
/// the contact plus its derived representative-account fields (already on
/// [contact]) and related-record counts. Per the API, only [dealCount] is
/// real — the rest have no backing model yet and should render as empty state.
class ContactOverview extends Equatable {
  final Contact contact;
  final int dealCount;
  final int? taskCount;
  final int? logCount;
  final List<String>? tags;
  final String? about;
  final DateTime? lastActivity;

  /// When the contact was created — always present on the overview response.
  final DateTime? createdAt;

  /// Who created it, from the audit log's CREATED entry. Null when no such
  /// entry exists (e.g. imported or seeded outside the audit-logged create
  /// path), so it can't be relied on even when [createdAt] is set.
  final String? createdByName;

  const ContactOverview({
    required this.contact,
    this.dealCount = 0,
    this.taskCount,
    this.logCount,
    this.tags,
    this.about,
    this.lastActivity,
    this.createdAt,
    this.createdByName,
  });

  @override
  List<Object?> get props => [
    contact,
    dealCount,
    taskCount,
    logCount,
    tags,
    about,
    lastActivity,
    createdAt,
    createdByName,
  ];
}

/// One row of the Contact Detail "Deals" tab (`GET /contacts/{id}/deals`).
/// A lightweight view — the deal-stage *name* isn't in this payload (only
/// `stage_id`), so the UI shows the id-derived stage or a neutral label.
class ContactDeal extends Equatable {
  final int id;
  final String dealName;
  final int? accountId;
  final double value;
  final String? currency;
  final int? stageId;
  final String? tier;
  final int? ownerId;
  final DateTime? expectedCloseDate;

  const ContactDeal({
    required this.id,
    required this.dealName,
    this.accountId,
    this.value = 0,
    this.currency,
    this.stageId,
    this.tier,
    this.ownerId,
    this.expectedCloseDate,
  });

  @override
  List<Object?> get props => [
    id,
    dealName,
    accountId,
    value,
    currency,
    stageId,
    tier,
    ownerId,
    expectedCloseDate,
  ];
}
