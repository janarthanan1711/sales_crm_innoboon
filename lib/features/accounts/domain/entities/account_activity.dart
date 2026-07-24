import 'package:equatable/equatable.dart';

/// One entry in an account's activity log. Response shape of
/// `POST/GET/PATCH /accounts/{account_id}/activities`.
class AccountActivity extends Equatable {
  final int id;
  final int accountId;
  final String type; // wire value: note/meeting/call/comment/follow_up
  final String note;
  final int createdBy;
  final DateTime createdAt;
  final String? createdByName;
  final int? updatedBy;
  final String? updatedByName;
  final DateTime? updatedAt;

  const AccountActivity({
    required this.id,
    required this.accountId,
    required this.type,
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
    accountId,
    type,
    note,
    createdBy,
    createdAt,
    createdByName,
    updatedBy,
    updatedByName,
    updatedAt,
  ];
}

/// Backend wire value <-> display label map for account activity types.
const Map<String, String> accountActivityTypeLabels = {
  'note': 'Note',
  'meeting': 'Meeting',
  'call': 'Call',
  'comment': 'Comment',
  'follow_up': 'Follow-up',
};

/// Display label for a wire value; falls back to the raw value if missing.
String accountActivityLabel(String? wireValue) {
  if (wireValue == null) return '';
  return accountActivityTypeLabels[wireValue] ?? wireValue;
}
