import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/activity.dart';
import '../repositories/activity_repository.dart';

class GetActivitiesParams {
  final String entityType;
  final String entityId;
  const GetActivitiesParams({required this.entityType, required this.entityId});
}

class GetActivitiesUseCase implements UseCase<List<AppActivity>, GetActivitiesParams> {
  final ActivityRepository repository;
  GetActivitiesUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<AppActivity>>> call(GetActivitiesParams params) => 
      repository.getActivities(params.entityType, params.entityId);
}

class LogActivityUseCase implements UseCase<AppActivity, AppActivity> {
  final ActivityRepository repository;
  LogActivityUseCase(this.repository);
  
  @override
  Future<Either<Failure, AppActivity>> call(AppActivity params) => 
      repository.logActivity(params);
}
