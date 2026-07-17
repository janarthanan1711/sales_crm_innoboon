import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../entities/stakeholder.dart';

abstract class DealRepository {
  Future<Either<Failure, List<Deal>>> getDeals({
    String? owner,
    String? tier,
    DealStage? stage,
  });
  Future<Either<Failure, Deal>> getDealById(String id);
  Future<Either<Failure, Deal>> createDeal(Deal deal);
  Future<Either<Failure, Deal>> updateDeal(Deal deal);
  Future<Either<Failure, Deal>> updateDealStage(String id, DealStage stage);
  Future<Either<Failure, Stakeholder>> addStakeholder(String dealId, Stakeholder stakeholder);
}

abstract class DealRemoteDataSource {
  Future<List<Deal>> getDeals({
    String? owner,
    String? tier,
    DealStage? stage,
  });
  Future<Deal> getDealById(String id);
  Future<Deal> createDeal(Deal deal);
  Future<Deal> updateDeal(Deal deal);
  Future<Deal> updateDealStage(String id, DealStage stage);
  Future<Stakeholder> addStakeholder(String dealId, Stakeholder stakeholder);
}
