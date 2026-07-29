import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_document.dart';
import '../../domain/entities/deal_document.dart';
import '../../domain/entities/document.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentDataSource dataSource;

  DocumentRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<Document>>> getDocuments({
    String? source,
    String? search,
  }) async {
    try {
      return Right(
        await dataSource.getDocuments(source: source, search: search),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountDocument>>> getAccountDocuments(
    String accountId,
  ) async {
    try {
      return Right(await dataSource.getAccountDocuments(accountId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountDocument>> uploadAccountDocument(
    String accountId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return Right(await dataSource.uploadAccountDocument(
        accountId,
        bytes: bytes,
        fileName: fileName,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccountDocument(
    String accountId,
    String documentId,
  ) async {
    try {
      await dataSource.deleteAccountDocument(accountId, documentId);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DealDocument>>> getDealDocuments(
    String dealId,
  ) async {
    try {
      return Right(await dataSource.getDealDocuments(dealId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DealDocument>> uploadDealDocument(
    String dealId, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      return Right(await dataSource.uploadDealDocument(
        dealId,
        bytes: bytes,
        fileName: fileName,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDealDocument(
    String dealId,
    String documentId,
  ) async {
    try {
      await dataSource.deleteDealDocument(dealId, documentId);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
