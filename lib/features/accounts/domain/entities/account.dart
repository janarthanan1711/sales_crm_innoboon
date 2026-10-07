import 'package:equatable/equatable.dart';

/// A contact to create inline with a new account (the `contacts[]` array on
/// `POST /accounts`). Per the API, `firstName` is only required on the first
/// contact — every later contact inherits the first's name automatically, so
/// only its email/phone are needed.
class AccountContactDraft extends Equatable {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobTitle;

  const AccountContactDraft({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phone, jobTitle];
}

/// Account entity — mirrors the backend's `AccountRead` shape (see
/// `POST/GET/PATCH /accounts`). The API has no embedded contacts list; the
/// full contact/deal rows are fetched separately via the dedicated
/// `GET /accounts/{id}/contacts` / `GET /accounts/{id}/deals` endpoints
/// (see [AccountRepository.getAccountContacts]/[getAccountDeals]), but the
/// account itself carries `contact_count`/`deal_count` for tab badges.
class Account extends Equatable {
  final String id;
  final String companyName;
  final String? domain;
  final String tier;
  final int? ownerId;

  /// Owner's display name — from the API's `owner_name`, falling back to
  /// "Owner {id}"/"Unassigned" when the server didn't resolve a name.
  final String primaryOwner;
  final String? industry;
  final String? city;

  /// Lead-source key (see `leadSourceLabels`), country name, and engagement
  /// type key (labels come from `GET /accounts/options`).
  final String? source;
  final String? country;
  final String? engagementType;
  final String? engagementTypeLabel;
  final String description;
  final String? linkedinUrl;
  final int? sourceLeadId;
  final int contactCount;
  final int dealCount;

  const Account({
    required this.id,
    required this.companyName,
    this.domain,
    required this.tier,
    this.ownerId,
    required this.primaryOwner,
    this.industry,
    this.city,
    this.source,
    this.country,
    this.engagementType,
    this.engagementTypeLabel,
    this.description = '',
    this.linkedinUrl,
    this.sourceLeadId,
    this.contactCount = 0,
    this.dealCount = 0,
  });

  Account copyWith({
    String? id,
    String? companyName,
    String? domain,
    String? tier,
    int? ownerId,
    String? primaryOwner,
    String? industry,
    String? city,
    String? source,
    String? country,
    String? engagementType,
    String? engagementTypeLabel,
    String? description,
    String? linkedinUrl,
    int? sourceLeadId,
    int? contactCount,
    int? dealCount,
  }) {
    return Account(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      domain: domain ?? this.domain,
      tier: tier ?? this.tier,
      ownerId: ownerId ?? this.ownerId,
      primaryOwner: primaryOwner ?? this.primaryOwner,
      industry: industry ?? this.industry,
      city: city ?? this.city,
      source: source ?? this.source,
      country: country ?? this.country,
      engagementType: engagementType ?? this.engagementType,
      engagementTypeLabel: engagementTypeLabel ?? this.engagementTypeLabel,
      description: description ?? this.description,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
      contactCount: contactCount ?? this.contactCount,
      dealCount: dealCount ?? this.dealCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyName,
    domain,
    tier,
    ownerId,
    primaryOwner,
    industry,
    city,
    source,
    country,
    engagementType,
    engagementTypeLabel,
    description,
    linkedinUrl,
    sourceLeadId,
    contactCount,
    dealCount,
  ];
}
