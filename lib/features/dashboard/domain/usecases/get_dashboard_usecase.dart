import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';
import '../entities/dashboard_range.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardParams extends Equatable {
  /// The reporting window — `this_week`, `this_month`, or a `custom` range.
  final DashboardRange range;
  final int limit;
  final int offset;

  const GetDashboardParams({
    this.range = const DashboardRange(),
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [range, limit, offset];
}

class GetDashboardUseCase {
  final DashboardRepository repository;
  GetDashboardUseCase(this.repository);

  Future<Either<Failure, DashboardData>> call(GetDashboardParams params) {
    return repository.getDashboard(
      range: params.range,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
