import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../entities/deal_stage_history.dart';

abstract class DealRepository {
  Future<Either<Failure, List<Deal>>> getDeals({
    int? ownerId,
    String? accountId,
    DealStage? stage,
    String? search,
  });
  Future<Either<Failure, Deal>> getDealById(String id);
  Future<Either<Failure, Deal>> createDeal({
    required String dealName,
    required String accountId,
    required double value,
    String currency = 'INR',
    DateTime? expectedCloseDate,
    required DealStage stage,
    int? ownerId,
  });
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
  });
  Future<Either<Failure, List<DealStageHistoryEntry>>> getStageHistory(
    String id,
  );
}

abstract class DealRemoteDataSource {
  Future<List<Deal>> getDeals({
    int? ownerId,
    String? accountId,
    DealStage? stage,
    String? search,
  });
  Future<Deal> getDealById(String id);
  Future<Deal> createDeal({
    required String dealName,
    required String accountId,
    required double value,
    String currency = 'INR',
    DateTime? expectedCloseDate,
    required DealStage stage,
    int? ownerId,
  });
  Future<Deal> updateDeal(
    String id, {
    String? dealName,
    double? value,
    String? currency,
    DateTime? expectedCloseDate,
    DealStage? stage,
    String? coldReason,
    int? ownerId,
    String? note,
  });
  Future<List<DealStageHistoryEntry>> getStageHistory(String id);
}
