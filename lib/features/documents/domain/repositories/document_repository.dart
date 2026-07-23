import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';

abstract class DocumentRepository {
  Future<Either<Failure, List<AccountDocument>>> getAccountDocuments(String accountId);
}

abstract class DocumentDataSource {
  Future<List<AccountDocument>> getAccountDocuments(String accountId);
}
