import 'package:equatable/equatable.dart';

/// A document attached to a deal. Mirrors the backend's document object
/// (`POST/GET /deals/{deal_id}/documents`). Files are served from the app's
/// static `/media/...` mount — [fileUrl] is a relative path that must be
/// prefixed with the server origin to open/download (see `mediaUrl`).
class DealDocument extends Equatable {
  final String id;
  final int dealId;
  final String fileName;
  final String fileUrl;
  final String contentType;
  final int uploadedBy;
  final DateTime createdAt;

  const DealDocument({
    required this.id,
    required this.dealId,
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
    dealId,
    fileName,
    fileUrl,
    contentType,
    uploadedBy,
    createdAt,
  ];
}
