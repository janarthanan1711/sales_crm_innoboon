import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../deals/domain/entities/deal.dart';
import '../repositories/account_repository.dart';

/// `GET /accounts/{id}/deals` — every deal on an account, as full `DealRead`
/// objects (value, currency, tier, expected close date, owner, contacts).
class GetAccountDealsUseCase {
  final AccountRepository repository;
  GetAccountDealsUseCase(this.repository);

  Future<Either<Failure, List<Deal>>> call(String accountId) =>
      repository.getAccountDeals(accountId);
}
