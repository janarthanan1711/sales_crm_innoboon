import 'package:equatable/equatable.dart';

/// Account entity — mirrors the backend's `AccountRead` shape (see
/// `POST/GET/PATCH /accounts`). The API has no embedded contacts list or
/// active-deals count — those are fetched separately via the dedicated
/// `GET /accounts/{id}/contacts` / `GET /accounts/{id}/deals` endpoints
/// (see [AccountRepository.getAccountContacts]/[getAccountDeals]).
class Account extends Equatable {
  final String id;
  final String companyName;
  final String? domain;
  final String tier;
  final int? ownerId;
  /// Display fallback (e.g. "Owner 12"/"Unassigned") — the API doesn't
  /// return an owner name on the account object, only `owner_id`.
  final String primaryOwner;
  final String? industry;
  final String? city;
  final String description;
  final String? linkedinUrl;
  final int? sourceLeadId;

  const Account({
    required this.id,
    required this.companyName,
    this.domain,
    required this.tier,
    this.ownerId,
    required this.primaryOwner,
    this.industry,
    this.city,
    this.description = '',
    this.linkedinUrl,
    this.sourceLeadId,
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
    String? description,
    String? linkedinUrl,
    int? sourceLeadId,
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
      description: description ?? this.description,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      sourceLeadId: sourceLeadId ?? this.sourceLeadId,
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
    description,
    linkedinUrl,
    sourceLeadId,
  ];
}
