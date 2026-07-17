import 'package:equatable/equatable.dart';
import 'contact.dart';

class Account extends Equatable {
  final String id;
  final String companyName;
  final String domain;
  final String industry;
  final String tier;
  final String primaryOwner;
  final String description;
  final List<Contact> contacts;
  final int activeDealsCount;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.companyName,
    required this.domain,
    required this.industry,
    required this.tier,
    required this.primaryOwner,
    required this.description,
    this.contacts = const [],
    this.activeDealsCount = 0,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? companyName,
    String? domain,
    String? industry,
    String? tier,
    String? primaryOwner,
    String? description,
    List<Contact>? contacts,
    int? activeDealsCount,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      domain: domain ?? this.domain,
      industry: industry ?? this.industry,
      tier: tier ?? this.tier,
      primaryOwner: primaryOwner ?? this.primaryOwner,
      description: description ?? this.description,
      contacts: contacts ?? this.contacts,
      activeDealsCount: activeDealsCount ?? this.activeDealsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        domain,
        industry,
        tier,
        primaryOwner,
        description,
        contacts,
        activeDealsCount,
        createdAt,
      ];
}
