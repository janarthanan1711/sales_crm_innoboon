import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class GetDealsParams {
  final int? ownerId;
  final String? accountId;
  final int? stageId;
  final String? search;

  const GetDealsParams({this.ownerId, this.accountId, this.stageId, this.search});
}

class GetDealsUseCase implements UseCase<List<Deal>, GetDealsParams> {
  final DealRepository repository;
  GetDealsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Deal>>> call(GetDealsParams params) =>
      repository.getDeals(
        ownerId: params.ownerId,
        accountId: params.accountId,
        stageId: params.stageId,
        search: params.search,
      );
}
