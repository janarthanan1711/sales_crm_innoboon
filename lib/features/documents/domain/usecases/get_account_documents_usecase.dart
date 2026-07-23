import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_document.dart';
import '../repositories/document_repository.dart';

class GetAccountDocumentsUseCase {
  final DocumentRepository repository;
  GetAccountDocumentsUseCase(this.repository);

  Future<Either<Failure, List<AccountDocument>>> call(String accountId) =>
      repository.getAccountDocuments(accountId);
}
