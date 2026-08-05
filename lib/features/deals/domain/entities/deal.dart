import 'package:equatable/equatable.dart';
import 'deal_contact.dart';
import 'stakeholder.dart';

/// Deal entity — mirrors the backend's `DealRead` shape. Stages are dynamic
/// (`stage_id` referencing `/deal-stages`), so this holds the numeric
/// [stageId] plus a client-resolved [stageName]/[stageIsCold] for display.
///
/// Fields the API does not carry ([description], [stakeholders],
/// [paymentStatus], [contactName], [createdAt]) are kept for UI convenience
/// and default to empty — they are populated by the caller, not the wire.
class Deal extends Equatable {
  final String id;
  final String name;
  final String accountId;
  final String accountName;

  /// Linked contacts with their resolved names, straight off the wire's
  /// `contacts` array. Writes still send ids only — see [contactIds].
  final List<DealContact> contacts;
  final String? contactName;
  final double value;
  final String currency;
  final int stageId;
  final String stageName;
  final bool stageIsCold;
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
    this.contacts = const [],
    this.contactName,
    required this.value,
    this.currency = 'INR',
    required this.stageId,
    this.stageName = '',
    this.stageIsCold = false,
    this.expectedCloseDate,
    this.ownerId,
    required this.owner,
    this.coldReason,
    this.tier = '',
    this.description = '',
    this.stakeholders = const [],
    this.paymentStatus = 'Pending',
    required this.createdAt,
  });

  /// Ids of the linked contacts — derived from [contacts], since writes
  /// (`POST`/`PATCH /deals`) send `contact_ids` while reads return `contacts`.
  List<int> get contactIds => contacts.map((c) => c.id).toList();

  /// Comma-separated contact names, for compact single-line display.
  String get contactNames => contacts.map((c) => c.name).join(', ');

  /// The stage as it should be shown to a user — never blank, and never a bare
  /// number. [stageName] is resolved from the `/deal-stages` catalog, which can
  /// come up empty (the request failed, or the stage was deleted); falling back
  /// to `Stage <id>` keeps the row identifiable instead of showing an empty
  /// chip.
  String get stageLabel =>
      stageName.trim().isEmpty ? 'Stage $stageId' : stageName;

  Deal copyWith({
    String? id,
    String? name,
    String? accountId,
    String? accountName,
    List<DealContact>? contacts,
    String? contactName,
    double? value,
    String? currency,
    int? stageId,
    String? stageName,
    bool? stageIsCold,
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
      contacts: contacts ?? this.contacts,
      contactName: contactName ?? this.contactName,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      stageId: stageId ?? this.stageId,
      stageName: stageName ?? this.stageName,
      stageIsCold: stageIsCold ?? this.stageIsCold,
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
    contacts,
    contactName,
    value,
    currency,
    stageId,
    stageName,
    stageIsCold,
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
