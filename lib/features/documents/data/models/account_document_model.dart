import '../../domain/entities/account_document.dart';

/// Parses the backend's account-document object.
AccountDocument accountDocumentFromJson(Map<String, dynamic> json) {
  return AccountDocument(
    id: '${json['id']}',
    accountId: json['account_id'] as int? ?? 0,
    fileName: json['file_name'] as String? ?? '',
    fileUrl: json['file_url'] as String? ?? '',
    contentType: json['content_type'] as String? ?? '',
    uploadedBy: json['uploaded_by'] as int? ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}
