import 'package:equatable/equatable.dart';

/// One entry in a deal's stage-change history — mirrors
/// `GET /deals/{id}/stage-history`.
///
/// The response identifies stages by numeric id (see `/deal-stages`), so names
/// are normally resolved client-side from the stage catalog. A stage that has
/// since been deleted is unrecoverable that way, so [fromStageName]/
/// [toStageName] are read from the payload when a build supplies them and take
/// precedence over the catalog lookup.
class DealStageHistoryEntry extends Equatable {
  final int id;
  final String dealId;
  final int? fromStageId;
  final int toStageId;
  final String? fromStageName;
  final String? toStageName;
  final int changedBy;
  final String? changedByName;
  final String? note;
  final DateTime createdAt;

  const DealStageHistoryEntry({
    required this.id,
    required this.dealId,
    this.fromStageId,
    required this.toStageId,
    this.fromStageName,
    this.toStageName,
    required this.changedBy,
    this.changedByName,
    this.note,
    required this.createdAt,
  });

  /// Only [changedByName] is replaceable — it's the one field the client fills
  /// in itself when the payload omits it (resolved from `GET /users`).
  DealStageHistoryEntry withChangedByName(String? name) =>
      DealStageHistoryEntry(
        id: id,
        dealId: dealId,
        fromStageId: fromStageId,
        toStageId: toStageId,
        fromStageName: fromStageName,
        toStageName: toStageName,
        changedBy: changedBy,
        changedByName: name ?? changedByName,
        note: note,
        createdAt: createdAt,
      );

  factory DealStageHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DealStageHistoryEntry(
      id: json['id'] as int,
      dealId: '${json['deal_id']}',
      fromStageId: json['from_stage_id'] as int?,
      toStageId: json['to_stage_id'] as int? ?? 0,
      fromStageName: json['from_stage_name'] as String?,
      toStageName: json['to_stage_name'] as String?,
      changedBy: json['changed_by'] as int? ?? 0,
      changedByName: json['changed_by_name'] as String?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    dealId,
    fromStageId,
    toStageId,
    fromStageName,
    toStageName,
    changedBy,
    changedByName,
    note,
    createdAt,
  ];
}
