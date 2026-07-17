import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sales_metrics.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SalesMetrics>> getSalesMetrics({String period = 'Monthly'}) async {
    try {
      final metrics = await remoteDataSource.getSalesMetrics(period: period);
      return Right(metrics);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
