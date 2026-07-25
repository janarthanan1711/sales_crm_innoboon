import '../../domain/entities/deal_document.dart';

/// Parses the backend's deal-document object.
DealDocument dealDocumentFromJson(Map<String, dynamic> json) {
  return DealDocument(
    id: '${json['id']}',
    dealId: json['deal_id'] as int? ?? 0,
    fileName: json['file_name'] as String? ?? '',
    fileUrl: json['file_url'] as String? ?? '',
    contentType: json['content_type'] as String? ?? '',
    uploadedBy: json['uploaded_by'] as int? ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
