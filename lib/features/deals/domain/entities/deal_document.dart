import 'package:equatable/equatable.dart';

/// A file attached to a deal — mirrors `GET/POST /deals/{id}/documents`.
class DealDocument extends Equatable {
  final int id;
  final String dealId;
  final String fileName;
  final String fileUrl;
  final String? contentType;
  final int? uploadedBy;
  final DateTime createdAt;

  const DealDocument({
    required this.id,
    required this.dealId,
    required this.fileName,
    required this.fileUrl,
    this.contentType,
    this.uploadedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, dealId, fileName, fileUrl, contentType, uploadedBy, createdAt];
}
