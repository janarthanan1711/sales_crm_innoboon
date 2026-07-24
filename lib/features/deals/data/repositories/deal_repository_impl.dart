import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_activity.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/repositories/deal_repository.dart';

class DealRepositoryImpl implements DealRepository {
  final DealRemoteDataSource remoteDataSource;

  DealRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Deal>>> getDeals({
    int? ownerId,
    String? accountId,
    int? stageId,
    String? search,
  }) async {
    try {
      final deals = await remoteDataSource.getDeals(
        ownerId: ownerId,
        accountId: accountId,
        stageId: stageId,
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
      return Right(await remoteDataSource.getDealById(id));
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
    required int stageId,
    List<int>? contactIds,
    String? tier,
    String? coldReason,
    int? ownerId,
  }) async {
    try {
      final deal = await remoteDataSource.createDeal(
        dealName: dealName,
        accountId: accountId,
        value: value,
        currency: currency,
        expectedCloseDate: expectedCloseDate,
        stageId: stageId,
        contactIds: contactIds,
        tier: tier,
        coldReason: coldReason,
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
    int? stageId,
    List<int>? contactIds,
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
        stageId: stageId,
        contactIds: contactIds,
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
  Future<Either<Failure, List<DealStageHistoryEntry>>> getStageHistory(String id) async {
    try {
      return Right(await remoteDataSource.getStageHistory(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DealStageDef>>> getDealStages() async {
    try {
      return Right(await remoteDataSource.getDealStages());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DealActivity>>> listActivities(
    String dealId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      return Right(await remoteDataSource.listActivities(
        dealId,
        types: types,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DealActivity>> logActivity(
    String dealId, {
    required String type,
    String? title,
    required String note,
  }) async {
    try {
      return Right(await remoteDataSource.logActivity(
        dealId,
        type: type,
        title: title,
        note: note,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DealActivity>> updateActivity(
    String dealId,
    String activityId, {
    String? type,
    String? title,
    String? note,
  }) async {
    try {
      return Right(await remoteDataSource.updateActivity(
        dealId,
        activityId,
        type: type,
        title: title,
        note: note,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteActivity(
    String dealId,
    String activityId,
  ) async {
    try {
      await remoteDataSource.deleteActivity(dealId, activityId);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
