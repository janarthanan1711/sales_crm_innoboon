import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity.dart';

abstract class ActivityRepository {
  Future<Either<Failure, List<AppActivity>>> getActivities(String entityType, String entityId);
  Future<Either<Failure, AppActivity>> logActivity(AppActivity activity);
}

abstract class ActivityRemoteDataSource {
  Future<List<AppActivity>> getActivities(String entityType, String entityId);
  Future<AppActivity> logActivity(AppActivity activity);
}
