import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_overview.dart';
import '../repositories/account_repository.dart';

class GetAccountOverviewUseCase {
  final AccountRepository repository;
  GetAccountOverviewUseCase(this.repository);

  Future<Either<Failure, AccountOverview>> call(String accountId) =>
      repository.getAccountOverview(accountId);
}
