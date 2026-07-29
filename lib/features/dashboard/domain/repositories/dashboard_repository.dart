import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_data.dart';

abstract class DashboardRepository {
  /// `GET /dashboard` — the single combined payload for the whole page.
  /// [period] is `today|this_week|this_month`, [granularity] is
  /// `daily|weekly|monthly` (drives the conversion-trend buckets), and
  /// [limit]/[offset] paginate the activity feed.
  Future<Either<Failure, DashboardData>> getDashboard({
    String period,
    String granularity,
    int limit,
    int offset,
  });
}

abstract class DashboardRemoteDataSource {
  Future<DashboardData> getDashboard({
    String period,
    String granularity,
    int limit,
    int offset,
  });
}
