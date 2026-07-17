import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sales_metrics.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, SalesMetrics>> getSalesMetrics({String period = 'Monthly'});
}

abstract class AnalyticsRemoteDataSource {
  Future<SalesMetrics> getSalesMetrics({String period = 'Monthly'});
}
