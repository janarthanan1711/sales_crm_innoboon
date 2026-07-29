import 'package:equatable/equatable.dart';

/// One row of the audit log (`GET /audit-log`). [description] is free-text and
/// its wording is NOT a stable contract — display it, never parse it.
class AuditLogEntry extends Equatable {
  final int id;
  final String tableName; // leads | accounts | deals | contacts | users
  final int recordId;
  final String action; // created|updated|deleted|login|logout|deactivated
  final int? actorId;
  final String actorName;
  final String description;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.action,
    this.actorId,
    required this.actorName,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    tableName,
    recordId,
    action,
    actorId,
    actorName,
    description,
    createdAt,
  ];
}

/// Fixed, code-defined enums (no lookup endpoint) — mirrored from the API doc.
const List<String> kAuditTableNames = [
  'leads',
  'accounts',
  'deals',
  'contacts',
  'users',
];

const List<String> kAuditActions = [
  'created',
  'updated',
  'deleted',
  'login',
  'logout',
  'deactivated',
];
