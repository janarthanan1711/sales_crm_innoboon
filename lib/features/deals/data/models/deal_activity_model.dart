import '../../domain/entities/deal_activity.dart';

/// Parses the backend's deal-activity object (API §6.9–6.11).
DealActivity dealActivityFromJson(Map<String, dynamic> json) {
  DateTime? parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String);
  return DealActivity(
    id: json['id'] as int,
    dealId: json['deal_id'] as int,
    type: json['type'] as String? ?? 'note',
    title: json['title'] as String?,
    note: json['note'] as String? ?? '',
    createdBy: json['created_by'] as int? ?? 0,
    createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    createdByName: json['created_by_name'] as String?,
    updatedBy: json['updated_by'] as int?,
    updatedByName: json['updated_by_name'] as String?,
    updatedAt: parseDate(json['updated_at']),
  );
}

/// Request body for `POST /deals/{deal_id}/activities`. `title` is sent only
/// when non-empty so backends that don't recognise it simply ignore it.
Map<String, dynamic> dealActivityCreateJson({
  required String type,
  String? title,
  required String note,
}) {
  return {
    'type': type,
    if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
    'note': note,
  };
}

/// Request body for `PATCH /deals/{deal_id}/activities/{activity_id}`.
Map<String, dynamic> dealActivityUpdateJson({
  String? type,
  String? title,
  String? note,
}) {
  return {
    if (type != null) 'type': type,
    if (title != null) 'title': title.trim(),
    if (note != null) 'note': note,
  };
}
