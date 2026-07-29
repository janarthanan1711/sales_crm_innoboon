import '../../domain/entities/document.dart';

/// Parses one item of the `GET /documents` union response.
Document documentFromJson(Map<String, dynamic> json) {
  return Document(
    id: (json['id'] as num?)?.toInt() ?? 0,
    source: json['source'] as String? ?? '',
    entityId: (json['entity_id'] as num?)?.toInt() ?? 0,
    entityName: json['entity_name'] as String? ?? '',
    fileName: json['file_name'] as String? ?? '',
    fileUrl: json['file_url'] as String? ?? '',
    contentType: json['content_type'] as String? ?? '',
    uploadedBy: (json['uploaded_by'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
