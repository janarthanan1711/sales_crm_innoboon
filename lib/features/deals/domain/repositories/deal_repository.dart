import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../entities/deal_activity.dart';
import '../entities/deal_stage_def.dart';
import '../entities/deal_stage_history.dart';

abstract class DealRepository {
  Future<Either<Failure, List<Deal>>> getDeals({
    int? ownerId,
    String? accountId,
    int? stageId,
    String? search,
  });
  Future<Either<Failure, Deal>> getDealById(String id);
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
  });
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
  });
  Future<Either<Failure, List<DealStageHistoryEntry>>> getStageHistory(String id);
  Future<Either<Failure, List<DealStageDef>>> getDealStages();

  Future<Either<Failure, List<DealActivity>>> listActivities(
    String dealId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<Either<Failure, DealActivity>> logActivity(
    String dealId, {
    required String type,
    String? title,
    required String note,
  });
  Future<Either<Failure, DealActivity>> updateActivity(
    String dealId,
    String activityId, {
    String? type,
    String? title,
    String? note,
  });
  Future<Either<Failure, Unit>> deleteActivity(
    String dealId,
    String activityId,
  );
}

abstract class DealRemoteDataSource {
  Future<List<Deal>> getDeals({
    int? ownerId,
    String? accountId,
    int? stageId,
    String? search,
  });
  Future<Deal> getDealById(String id);
  Future<Deal> createDeal({
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
  });
  Future<Deal> updateDeal(
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
  });
  Future<List<DealStageHistoryEntry>> getStageHistory(String id);
  Future<List<DealStageDef>> getDealStages();

  Future<List<DealActivity>> listActivities(
    String dealId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<DealActivity> logActivity(
    String dealId, {
    required String type,
    String? title,
    required String note,
  });
  Future<DealActivity> updateActivity(
    String dealId,
    String activityId, {
    String? type,
    String? title,
    String? note,
  });
  Future<void> deleteActivity(String dealId, String activityId);
}
