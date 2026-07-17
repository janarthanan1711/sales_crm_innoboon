import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class GetDealsParams {
  final String? owner;
  final String? tier;
  final DealStage? stage;

  const GetDealsParams({this.owner, this.tier, this.stage});
}

class GetDealsUseCase implements UseCase<List<Deal>, GetDealsParams> {
  final DealRepository repository;
  GetDealsUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<Deal>>> call(GetDealsParams params) => 
      repository.getDeals(owner: params.owner, tier: params.tier, stage: params.stage);
}
