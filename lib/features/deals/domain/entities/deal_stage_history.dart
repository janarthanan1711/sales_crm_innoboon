import 'package:equatable/equatable.dart';
import 'deal.dart';

/// One entry in a deal's stage-change history — mirrors
/// `GET /deals/{id}/stage-history`.
class DealStageHistoryEntry extends Equatable {
  final int id;
  final String dealId;
  final DealStage? fromStage;
  final DealStage toStage;
  final int changedBy;
  final String? note;
  final DateTime createdAt;

  const DealStageHistoryEntry({
    required this.id,
    required this.dealId,
    this.fromStage,
    required this.toStage,
    required this.changedBy,
    this.note,
    required this.createdAt,
  });

  factory DealStageHistoryEntry.fromJson(Map<String, dynamic> json) {
    return DealStageHistoryEntry(
      id: json['id'] as int,
      dealId: '${json['deal_id']}',
      fromStage: json['from_stage'] != null
          ? dealStageFromWire(json['from_stage'] as String)
          : null,
      toStage: dealStageFromWire(json['to_stage'] as String),
      changedBy: json['changed_by'] as int,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    id,
    dealId,
    fromStage,
    toStage,
    changedBy,
    note,
    createdAt,
  ];
}
