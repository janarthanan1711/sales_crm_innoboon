import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';
import '../entities/deal_document.dart';
import '../entities/document.dart';

abstract class DocumentRepository {
  /// `GET /documents` — the union of Account + Deal documents the caller can
  /// see, newest first. [source] is `account`|`deal` (null for both);
  /// [search] is a case-insensitive substring match on the file name.
  Future<Either<Failure, List<Document>>> getDocuments({
    String? source,
    String? search,
  });

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

  Future<Either<Failure, List<DealDocument>>> getDealDocuments(String dealId);
  Future<Either<Failure, DealDocument>> uploadDealDocument(
    String dealId, {
    required Uint8List bytes,
    required String fileName,
  });
  Future<Either<Failure, Unit>> deleteDealDocument(
    String dealId,
    String documentId,
  );
}

abstract class DocumentDataSource {
  Future<List<Document>> getDocuments({String? source, String? search});

  Future<List<AccountDocument>> getAccountDocuments(String accountId);
  Future<AccountDocument> uploadAccountDocument(
    String accountId, {
    required Uint8List bytes,
    required String fileName,
  });
  Future<void> deleteAccountDocument(String accountId, String documentId);

  Future<List<DealDocument>> getDealDocuments(String dealId);
  Future<DealDocument> uploadDealDocument(
    String dealId, {
    required Uint8List bytes,
    required String fileName,
  });
  Future<void> deleteDealDocument(String dealId, String documentId);
}
