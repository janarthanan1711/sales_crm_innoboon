import 'package:equatable/equatable.dart';

/// One entry in a deal's stage-change history — mirrors
/// `GET /deals/{id}/stage-history`. Stages are numeric ids (see
/// `/deal-stages`); names are resolved client-side from the stage catalog.
class DealStageHistoryEntry extends Equatable {
  final int id;
  final String dealId;
  final int? fromStageId;
  final int toStageId;
  final int changedBy;
  final String? note;
  final DateTime createdAt;

  const DealStageHistoryEntry({
    required this.id,
    required this.dealId,
    this.fromStageId,
    required this.toStageId,
    required this.changedBy,
    this.note,
    required this.createdAt,
  });

  factory DealStageHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DealStageHistoryEntry(
      id: json['id'] as int,
      dealId: '${json['deal_id']}',
      fromStageId: json['from_stage_id'] as int?,
      toStageId: json['to_stage_id'] as int? ?? 0,
      changedBy: json['changed_by'] as int? ?? 0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, dealId, fromStageId, toStageId, changedBy, note, createdAt];
}
