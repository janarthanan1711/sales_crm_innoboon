import 'package:equatable/equatable.dart';

/// A row of the sidebar Documents page — the union of Account and Deal
/// documents (`GET /documents`). [id] is only unique *within* its [source]
/// (an account doc and a deal doc can share an id), so use [key] as the
/// stable identity. Files are served from the static `/media/...` mount, so
/// [fileUrl] is relative and must be resolved against the API origin to open.
class Document extends Equatable {
  final int id;
  final String source; // 'account' | 'deal'
  final int entityId;
  final String entityName;
  final String fileName;
  final String fileUrl;
  final String contentType;
  final int uploadedBy;
  final DateTime createdAt;

  const Document({
    required this.id,
    required this.source,
    required this.entityId,
    required this.entityName,
    required this.fileName,
    required this.fileUrl,
    required this.contentType,
    required this.uploadedBy,
    required this.createdAt,
  });

  bool get isAccount => source == 'account';

  /// Composite identity: unique across the merged list.
  String get key => '$source-$id';

  /// File extension (lowercased, no dot) — drives the row icon.
  String get extension {
    final dot = fileName.lastIndexOf('.');
    return dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [
    id,
    source,
    entityId,
    entityName,
    fileName,
    fileUrl,
    contentType,
    uploadedBy,
    createdAt,
  ];
}
