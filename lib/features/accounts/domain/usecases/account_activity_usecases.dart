import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_activity.dart';
import '../repositories/account_repository.dart';

class ListAccountActivitiesParams {
  final String accountId;
  final List<String>? types;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  const ListAccountActivitiesParams({
    required this.accountId,
    this.types,
    this.dateFrom,
    this.dateTo,
  });
}

class ListAccountActivitiesUseCase {
  final AccountRepository repository;
  ListAccountActivitiesUseCase(this.repository);

  Future<Either<Failure, List<AccountActivity>>> call(
    ListAccountActivitiesParams params,
  ) {
    return repository.listActivities(
      params.accountId,
      types: params.types,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    );
  }
}

class LogAccountActivityParams {
  final String accountId;
  final String type;
  final String note;
  const LogAccountActivityParams({
    required this.accountId,
    required this.type,
    required this.note,
  });
}

class LogAccountActivityUseCase {
  final AccountRepository repository;
  LogAccountActivityUseCase(this.repository);

  Future<Either<Failure, AccountActivity>> call(
    LogAccountActivityParams params,
  ) {
    return repository.logActivity(
      params.accountId,
      type: params.type,
      note: params.note,
    );
  }
}

class UpdateAccountActivityParams {
  final String accountId;
  final String activityId;
  final String? type;
  final String? note;
  const UpdateAccountActivityParams({
    required this.accountId,
    required this.activityId,
    this.type,
    this.note,
  });
}

class UpdateAccountActivityUseCase {
  final AccountRepository repository;
  UpdateAccountActivityUseCase(this.repository);

  Future<Either<Failure, AccountActivity>> call(
    UpdateAccountActivityParams params,
  ) {
    return repository.updateActivity(
      params.accountId,
      params.activityId,
      type: params.type,
      note: params.note,
    );
  }
}

class DeleteAccountActivityParams {
  final String accountId;
  final String activityId;
  const DeleteAccountActivityParams({
    required this.accountId,
    required this.activityId,
  });
}

class DeleteAccountActivityUseCase {
  final AccountRepository repository;
  DeleteAccountActivityUseCase(this.repository);

  Future<Either<Failure, Unit>> call(DeleteAccountActivityParams params) {
    return repository.deleteActivity(params.accountId, params.activityId);
  }
}
