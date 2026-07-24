import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal_activity.dart';
import '../repositories/deal_repository.dart';

class ListDealActivitiesParams {
  final String dealId;
  final List<String>? types;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  const ListDealActivitiesParams({
    required this.dealId,
    this.types,
    this.dateFrom,
    this.dateTo,
  });
}

class ListDealActivitiesUseCase {
  final DealRepository repository;
  ListDealActivitiesUseCase(this.repository);

  Future<Either<Failure, List<DealActivity>>> call(
    ListDealActivitiesParams params,
  ) {
    return repository.listActivities(
      params.dealId,
      types: params.types,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    );
  }
}

class LogDealActivityParams {
  final String dealId;
  final String type;
  final String? title;
  final String note;
  const LogDealActivityParams({
    required this.dealId,
    required this.type,
    this.title,
    required this.note,
  });
}

class LogDealActivityUseCase {
  final DealRepository repository;
  LogDealActivityUseCase(this.repository);

  Future<Either<Failure, DealActivity>> call(LogDealActivityParams params) {
    return repository.logActivity(
      params.dealId,
      type: params.type,
      title: params.title,
      note: params.note,
    );
  }
}

class UpdateDealActivityParams {
  final String dealId;
  final String activityId;
  final String? type;
  final String? title;
  final String? note;
  const UpdateDealActivityParams({
    required this.dealId,
    required this.activityId,
    this.type,
    this.title,
    this.note,
  });
}

class UpdateDealActivityUseCase {
  final DealRepository repository;
  UpdateDealActivityUseCase(this.repository);

  Future<Either<Failure, DealActivity>> call(UpdateDealActivityParams params) {
    return repository.updateActivity(
      params.dealId,
      params.activityId,
      type: params.type,
      title: params.title,
      note: params.note,
    );
  }
}

class DeleteDealActivityParams {
  final String dealId;
  final String activityId;
  const DeleteDealActivityParams({
    required this.dealId,
    required this.activityId,
  });
}

class DeleteDealActivityUseCase {
  final DealRepository repository;
  DeleteDealActivityUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DeleteDealActivityParams params) {
    return repository.deleteActivity(params.dealId, params.activityId);
  }
}
