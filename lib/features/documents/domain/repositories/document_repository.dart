import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';

abstract class DocumentRepository {
  Future<Either<Failure, List<AccountDocument>>> getAccountDocuments(
    String accountId,
  );
  Future<Either<Failure, AccountDocument>> uploadAccountDocument(
    String accountId, {
    required Uint8List bytes,
    required String fileName,
  });
  Future<Either<Failure, Unit>> deleteAccountDocument(
    String accountId,
    String documentId,
  );
}

abstract class DocumentDataSource {
  Future<List<AccountDocument>> getAccountDocuments(String accountId);
  Future<AccountDocument> uploadAccountDocument(
    String accountId, {
    required Uint8List bytes,
    required String fileName,
  });
  Future<void> deleteAccountDocument(String accountId, String documentId);
}
