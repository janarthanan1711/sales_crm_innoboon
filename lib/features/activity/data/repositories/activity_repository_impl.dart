import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;

  ActivityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<AppActivity>>> getActivities(String entityType, String entityId) async {
    try {
      final activities = await remoteDataSource.getActivities(entityType, entityId);
      return Right(activities);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppActivity>> logActivity(AppActivity activity) async {
    try {
      final created = await remoteDataSource.logActivity(activity);
      return Right(created);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
