import 'package:equatable/equatable.dart';

/// A document attached to an account. Mirrors the backend's document object
/// (`POST/GET /accounts/{account_id}/documents`). Files are served from the
/// app's static `/media/...` mount — [fileUrl] is a relative path that must be
/// prefixed with the server origin to open/download (see `mediaUrl`).
class AccountDocument extends Equatable {
  final String id;
  final int accountId;
  final String fileName;
  final String fileUrl;
  final String contentType;
  final int uploadedBy;
  final DateTime createdAt;

  const AccountDocument({
    required this.id,
    required this.accountId,
    required this.fileName,
    required this.fileUrl,
    required this.contentType,
    required this.uploadedBy,
    required this.createdAt,
  });

  /// Display name (the tab renders this as the row title).
  String get name => fileName;

  /// File extension (lowercased, no dot) — drives the row icon.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    fileName,
    fileUrl,
    contentType,
    uploadedBy,
    createdAt,
  ];
}
