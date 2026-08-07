import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';
import '../entities/dashboard_range.dart';

abstract class DashboardRepository {
  /// `GET /dashboard` — the single combined payload for the whole page.
  /// [range] carries the period (`this_week|this_month|custom`) plus the
  /// start/end bounds `custom` requires; its [DashboardRange.granularity]
  /// drives the conversion-trend buckets. [limit]/[offset] paginate the
  /// activity feed.
  Future<Either<Failure, DashboardData>> getDashboard({
    DashboardRange range,
    int limit,
    int offset,
  });
}

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboard({
    DashboardRange range,
    int limit,
    int offset,
  });
}
