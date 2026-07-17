import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetAccountsParams {
  final String? search;
  final String? industry;
  final String? tier;
  final String? owner;

  const GetAccountsParams({
    this.search,
    this.industry,
    this.tier,
    this.owner,
  });
}

class GetAccountsUseCase implements UseCase<List<Account>, GetAccountsParams> {
  final AccountRepository repository;
  GetAccountsUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<Account>>> call(GetAccountsParams params) => 
      repository.getAccounts(
        search: params.search,
        industry: params.industry,
        tier: params.tier,
        owner: params.owner,
      );
}
