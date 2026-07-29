import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';
import '../entities/deal_document.dart';
import '../entities/document.dart';
import '../repositories/document_repository.dart';

// ─── Combined documents list (sidebar Documents page) ────

class GetDocumentsParams {
  final String? source; // 'account' | 'deal' | null (both)
  final String? search;
  const GetDocumentsParams({this.source, this.search});
}

class GetDocumentsUseCase {
  final DocumentRepository repository;
  GetDocumentsUseCase(this.repository);

  Future<Either<Failure, List<Document>>> call(GetDocumentsParams params) {
    return repository.getDocuments(source: params.source, search: params.search);
  }
}

class UploadAccountDocumentParams {
  final String accountId;
  final Uint8List bytes;
  final String fileName;
  const UploadAccountDocumentParams({
    required this.accountId,
    required this.bytes,
    required this.fileName,
  });
}

class UploadAccountDocumentUseCase {
  final DocumentRepository repository;
  UploadAccountDocumentUseCase(this.repository);

  Future<Either<Failure, AccountDocument>> call(
    UploadAccountDocumentParams params,
  ) {
    return repository.uploadAccountDocument(
      params.accountId,
      bytes: params.bytes,
      fileName: params.fileName,
    );
  }
}

class DeleteAccountDocumentParams {
  final String accountId;
  final String documentId;
  const DeleteAccountDocumentParams({
    required this.accountId,
    required this.documentId,
  });
}

class DeleteAccountDocumentUseCase {
  final DocumentRepository repository;
  DeleteAccountDocumentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DeleteAccountDocumentParams params) {
    return repository.deleteAccountDocument(params.accountId, params.documentId);
  }
}

// ─── Deal documents ──────────────────────────────────────

class GetDealDocumentsUseCase {
  final DocumentRepository repository;
  GetDealDocumentsUseCase(this.repository);

  Future<Either<Failure, List<DealDocument>>> call(String dealId) =>
      repository.getDealDocuments(dealId);
}

class UploadDealDocumentParams {
  final String dealId;
  final Uint8List bytes;
  final String fileName;
  const UploadDealDocumentParams({
    required this.dealId,
    required this.bytes,
    required this.fileName,
  });
}

class UploadDealDocumentUseCase {
  final DocumentRepository repository;
  UploadDealDocumentUseCase(this.repository);

  Future<Either<Failure, DealDocument>> call(UploadDealDocumentParams params) {
    return repository.uploadDealDocument(
      params.dealId,
      bytes: params.bytes,
      fileName: params.fileName,
    );
  }
}

class DeleteDealDocumentParams {
  final String dealId;
  final String documentId;
  const DeleteDealDocumentParams({
    required this.dealId,
    required this.documentId,
  });
}

class DeleteDealDocumentUseCase {
  final DocumentRepository repository;
  DeleteDealDocumentUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DeleteDealDocumentParams params) {
    return repository.deleteDealDocument(params.dealId, params.documentId);
  }
}
