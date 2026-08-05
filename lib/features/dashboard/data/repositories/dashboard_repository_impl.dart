import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_range.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DashboardData>> getDashboard({
    DashboardRange range = const DashboardRange(),
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await remoteDataSource.getDashboard(
        range: range,
        limit: limit,
        offset: offset,
      );
      return Right(data);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
