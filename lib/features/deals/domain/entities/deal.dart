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
  final String owner;
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
    required this.owner,
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
    String? owner,
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
      owner: owner ?? this.owner,
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
        owner,
        tier,
        description,
        stakeholders,
        paymentStatus,
        createdAt,
      ];
}
