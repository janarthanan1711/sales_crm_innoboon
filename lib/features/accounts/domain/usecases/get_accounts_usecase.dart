import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetAccountsParams {
  final String? search;
  final String? industry;
  final String? tier;
  final int? ownerId;
  final int limit;
  final int offset;

  const GetAccountsParams({
    this.search,
    this.industry,
    this.tier,
    this.ownerId,
    this.limit = 25,
    this.offset = 0,
  });
}

class GetAccountsUseCase
    implements UseCase<({List<Account> items, int total}), GetAccountsParams> {
  final AccountRepository repository;
  GetAccountsUseCase(this.repository);

  @override
  Future<Either<Failure, ({List<Account> items, int total})>> call(
    GetAccountsParams params,
  ) =>
      repository.getAccounts(
        search: params.search,
        industry: params.industry,
        tier: params.tier,
        ownerId: params.ownerId,
        limit: params.limit,
        offset: params.offset,
      );
}
