import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardParams extends Equatable {
  final String period; // today | this_week | this_month
  final String granularity; // daily | weekly | monthly
  final int limit;
  final int offset;

  const GetDashboardParams({
    this.period = 'this_month',
    this.granularity = 'monthly',
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [period, granularity, limit, offset];
}

class GetDashboardUseCase {
  final DashboardRepository repository;
  GetDashboardUseCase(this.repository);

  Future<Either<Failure, DashboardData>> call(GetDashboardParams params) {
    return repository.getDashboard(
      period: params.period,
      granularity: params.granularity,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
