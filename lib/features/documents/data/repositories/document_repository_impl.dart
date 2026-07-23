import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_document.dart';
import '../../domain/repositories/document_repository.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentDataSource dataSource;

  DocumentRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<AccountDocument>>> getAccountDocuments(String accountId) async {
    try {
      return Right(await dataSource.getAccountDocuments(accountId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
