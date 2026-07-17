import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sales_metrics.dart';
import '../repositories/analytics_repository.dart';

class GetSalesMetricsParams {
  final String period;
  const GetSalesMetricsParams({this.period = 'Monthly'});
}

class GetSalesMetricsUseCase implements UseCase<SalesMetrics, GetSalesMetricsParams> {
  final AnalyticsRepository repository;
  GetSalesMetricsUseCase(this.repository);
  
  @override
  Future<Either<Failure, SalesMetrics>> call(GetSalesMetricsParams params) => 
      repository.getSalesMetrics(period: params.period);
}
