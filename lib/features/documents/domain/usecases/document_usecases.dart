import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';
import '../repositories/document_repository.dart';

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
