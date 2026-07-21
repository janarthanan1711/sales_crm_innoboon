import 'package:equatable/equatable.dart';
import 'stakeholder.dart';

enum DealStage {
  receivedRequirements,
  qualifiedToBuy,
  evaluation,
  proposals,
  contracts,
  closedWon,
  closedLost,
  coldDeals
}

extension DealStageExtension on DealStage {
  String get name {
    switch (this) {
      case DealStage.receivedRequirements: return 'Received Requirements';
      case DealStage.qualifiedToBuy: return 'Qualified to Buy';
      case DealStage.evaluation: return 'Evaluation';
      case DealStage.proposals: return 'Proposals';
      case DealStage.contracts: return 'Contracts';
      case DealStage.closedWon: return 'Closed Won';
      case DealStage.closedLost: return 'Closed Lost';
      case DealStage.coldDeals: return 'Cold Deals';
    }
  }

  /// Backend wire value — see `saleshub`'s deal-stage enum.
  String get wireValue {
    switch (this) {
      case DealStage.receivedRequirements: return 'received_requirements';
      case DealStage.qualifiedToBuy: return 'qualified_to_buy';
      case DealStage.evaluation: return 'evaluation';
      case DealStage.proposals: return 'proposals';
      case DealStage.contracts: return 'contracts';
      case DealStage.closedWon: return 'closed_won';
      case DealStage.closedLost: return 'closed_lost';
      case DealStage.coldDeals: return 'cold_deals';
    }
  }
}

/// Backend wire value -> [DealStage]; falls back to [DealStage.receivedRequirements]
/// if the backend ever sends an unrecognized value.
DealStage dealStageFromWire(String wire) {
  return DealStage.values.firstWhere(
    (s) => s.wireValue == wire,
    orElse: () => DealStage.receivedRequirements,
  );
}

class Deal extends Equatable {
  final String id;
  final String name;
  final String accountId;
  final String accountName;
  final String? contactId;
  final String? contactName;
  final double value;
  final String currency;
  final DealStage stage;
  final DateTime? expectedCloseDate;
  final int? ownerId;
  final String owner;
  final String? coldReason;
  final String tier;
  final String description;
  final List<Stakeholder> stakeholders;
  final String paymentStatus;
  final DateTime createdAt;

  const Deal({
    required this.id,
    required this.name,
    required this.accountId,
    required this.accountName,
    this.contactId,
    this.contactName,
    required this.value,
    this.currency = 'INR',
    required this.stage,
    this.expectedCloseDate,
    this.ownerId,
    required this.owner,
    this.coldReason,
    required this.tier,
    this.description = '',
    this.stakeholders = const [],
    this.paymentStatus = 'Pending',
    required this.createdAt,
  });

  Deal copyWith({
    String? id,
    String? name,
    String? accountId,
    String? accountName,
    String? contactId,
    String? contactName,
    double? value,
    String? currency,
    DealStage? stage,
    DateTime? expectedCloseDate,
    int? ownerId,
    String? owner,
    String? coldReason,
    String? tier,
    String? description,
    List<Stakeholder>? stakeholders,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return Deal(
      id: id ?? this.id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      stage: stage ?? this.stage,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      coldReason: coldReason ?? this.coldReason,
      tier: tier ?? this.tier,
      description: description ?? this.description,
      stakeholders: stakeholders ?? this.stakeholders,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        accountId,
        accountName,
        contactId,
        contactName,
        value,
        currency,
        stage,
        expectedCloseDate,
        ownerId,
        owner,
        coldReason,
        tier,
        description,
        stakeholders,
        paymentStatus,
        createdAt,
      ];
}
