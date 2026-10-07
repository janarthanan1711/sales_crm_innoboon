import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_options.dart';
import '../entities/source_person.dart';
import '../repositories/account_repository.dart';

class GetAccountOptionsUseCase {
  final AccountRepository repository;
  GetAccountOptionsUseCase(this.repository);

  Future<Either<Failure, AccountOptions>> call() =>
      repository.getAccountOptions();
}

/// Everyone selectable in the Source Detail chain (users + contacts).
class GetSourcePeopleUseCase {
  final AccountRepository repository;
  GetSourcePeopleUseCase(this.repository);

  Future<Either<Failure, List<SourcePerson>>> call() =>
      repository.getSourcePeople();
}

class GetSourceDetailUseCase {
  final AccountRepository repository;
  GetSourceDetailUseCase(this.repository);

  Future<Either<Failure, List<SourcePerson>>> call(String accountId) =>
      repository.getSourceDetail(accountId);
}

class SaveSourceDetailUseCase {
  final AccountRepository repository;
  SaveSourceDetailUseCase(this.repository);

  Future<Either<Failure, List<SourcePerson>>> call(
    String accountId,
    List<SourcePerson> members,
  ) => repository.saveSourceDetail(accountId, members);
}
