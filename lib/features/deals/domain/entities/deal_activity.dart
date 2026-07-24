import 'package:equatable/equatable.dart';

/// One entry in a deal's activity log. Response shape of
/// `POST/GET/PATCH /deals/{deal_id}/activities` (see API §6.9–6.12).
///
/// [title] is a UI-only convenience field not present in the base API doc;
/// it is sent on create/update and parsed back when the backend echoes it,
/// degrading gracefully (null) when it doesn't.
class DealActivity extends Equatable {
  final int id;
  final int dealId;
  final String type; // wire value: note/meeting/call/comment/follow_up
  final String? title;
  final String note;
  final int createdBy;
  final DateTime createdAt;
  final String? createdByName;
  final int? updatedBy;
  final String? updatedByName;
  final DateTime? updatedAt;

  const DealActivity({
    required this.id,
    required this.dealId,
    required this.type,
    this.title,
    required this.note,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
    this.updatedBy,
    this.updatedByName,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    dealId,
    type,
    title,
    note,
    createdBy,
    createdAt,
    createdByName,
    updatedBy,
    updatedByName,
    updatedAt,
  ];
}
