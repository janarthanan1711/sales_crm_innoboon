import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/stakeholder.dart';
import '../../domain/repositories/deal_repository.dart';

class DealRepositoryImpl implements DealRepository {
  final DealRemoteDataSource remoteDataSource;

  DealRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Deal>>> getDeals({
    String? owner,
    String? tier,
    DealStage? stage,
  }) async {
    try {
      final deals = await remoteDataSource.getDeals(owner: owner, tier: tier, stage: stage);
      return Right(deals);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> getDealById(String id) async {
    try {
      final deal = await remoteDataSource.getDealById(id);
      return Right(deal);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> createDeal(Deal deal) async {
    try {
      final created = await remoteDataSource.createDeal(deal);
      return Right(created);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> updateDeal(Deal deal) async {
    try {
      final updated = await remoteDataSource.updateDeal(deal);
      return Right(updated);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> updateDealStage(String id, DealStage stage) async {
    try {
      final updated = await remoteDataSource.updateDealStage(id, stage);
      return Right(updated);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Stakeholder>> addStakeholder(String dealId, Stakeholder stakeholder) async {
    try {
      final added = await remoteDataSource.addStakeholder(dealId, stakeholder);
      return Right(added);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
