import '../../domain/entities/account_activity.dart';

/// Parses the backend's account-activity object.
AccountActivity accountActivityFromJson(Map<String, dynamic> json) {
  DateTime? parseDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v as String);
  return AccountActivity(
    id: json['id'] as int,
    accountId: json['account_id'] as int,
    type: json['type'] as String? ?? 'note',
    note: json['note'] as String? ?? '',
    createdBy: json['created_by'] as int? ?? 0,
    createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    createdByName: json['created_by_name'] as String?,
    updatedBy: json['updated_by'] as int?,
    updatedByName: json['updated_by_name'] as String?,
    updatedAt: parseDate(json['updated_at']),
  );
}
