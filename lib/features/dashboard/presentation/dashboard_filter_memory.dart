import '../domain/entities/dashboard_range.dart';

/// Remembers the dashboard's last-applied period/date range across page
/// visits.
///
/// `DashboardBloc` is registered as a factory (a fresh instance per visit,
/// like every other bloc in this app) and `DashboardPage` is torn down
/// whenever you navigate elsewhere -- GoRouter doesn't keep shell pages alive
/// in the background -- so without this, coming back to the dashboard always
/// rebuilds the bloc from its `This Month` default and the filter you picked
/// is gone. This is a plain singleton (not a bloc), so it survives that.
class DashboardFilterMemory {
  DashboardRange? lastRange;
}
