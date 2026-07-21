import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/repositories/deal_repository.dart';

class DealRepositoryImpl implements DealRepository {
  final DealRemoteDataSource remoteDataSource;

  DealRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Deal>>> getDeals({
    int? ownerId,
    String? accountId,
    DealStage? stage,
    String? search,
  }) async {
    try {
      final deals = await remoteDataSource.getDeals(
        ownerId: ownerId,
        accountId: accountId,
        stage: stage,
        search: search,
      );
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
  Future<Either<Failure, Deal>> createDeal({
    required String dealName,
    required String accountId,
    required double value,
    String currency = 'INR',
    DateTime? expectedCloseDate,
    required DealStage stage,
    int? ownerId,
  }) async {
    try {
      final deal = await remoteDataSource.createDeal(
        dealName: dealName,
        accountId: accountId,
        value: value,
        currency: currency,
        expectedCloseDate: expectedCloseDate,
        stage: stage,
        ownerId: ownerId,
      );
      return Right(deal);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Deal>> updateDeal(
    String id, {
    String? dealName,
    double? value,
    String? currency,
    DateTime? expectedCloseDate,
    DealStage? stage,
    String? coldReason,
    int? ownerId,
    String? note,
  }) async {
    try {
      final deal = await remoteDataSource.updateDeal(
        id,
        dealName: dealName,
        value: value,
        currency: currency,
        expectedCloseDate: expectedCloseDate,
        stage: stage,
        coldReason: coldReason,
        ownerId: ownerId,
        note: note,
      );
      return Right(deal);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DealStageHistoryEntry>>> getStageHistory(
    String id,
  ) async {
    try {
      return Right(await remoteDataSource.getStageHistory(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
