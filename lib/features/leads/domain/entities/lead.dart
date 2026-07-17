import 'package:equatable/equatable.dart';

/// Lead entity — domain layer
class Lead extends Equatable {
  final String id;
  final String companyName;
  final String contactName;
  final String email;
  final String? phone;
  final String source;
  final String status; // New, Contacted, Junk, Closed, Contact in Future
  final String?
  tier; // Always empty/null for leads — set only after conversion to Account
  final String? owner; // Defaults to empty if not explicitly assigned
  final String? website;
  final String? industry;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastContactedAt;

  const Lead({
    required this.id,
    required this.companyName,
    required this.contactName,
    required this.email,
    this.phone,
    required this.source,
    required this.status,
    this.tier,
    this.owner,
    this.website,
    this.industry,
    this.notes,
    required this.createdAt,
    this.lastContactedAt,
  });

  Lead copyWith({
    String? id,
    String? companyName,
    String? contactName,
    String? email,
    String? phone,
    String? source,
    String? status,
    String? tier,
    String? owner,
    String? website,
    String? industry,
    String? notes,
    DateTime? createdAt,
    DateTime? lastContactedAt,
  }) {
    return Lead(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      source: source ?? this.source,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      owner: owner ?? this.owner,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastContactedAt: lastContactedAt ?? this.lastContactedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    companyName,
    contactName,
    email,
    status,
    tier,
  ];
}
