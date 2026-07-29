import '../../domain/entities/audit_log_entry.dart';

AuditLogEntry auditLogEntryFromJson(Map<String, dynamic> json) {
  return AuditLogEntry(
    id: (json['id'] as num?)?.toInt() ?? 0,
    tableName: json['table_name'] as String? ?? '',
    recordId: (json['record_id'] as num?)?.toInt() ?? 0,
    action: json['action'] as String? ?? '',
    actorId: (json['actor_id'] as num?)?.toInt(),
    actorName: json['actor_name'] as String? ?? 'System',
    description: json['description'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
