import 'package:equatable/equatable.dart';

/// The dashboard's selected reporting window.
///
/// [period] is the wire value sent as `GET /dashboard?period=`. `today` was
/// dropped from the filter — a single day is now expressed as a [custom] range
/// with the same [start] and [end], which keeps the toggle to three options
/// while covering strictly more cases.
///
/// [start]/[end] are only set — and only sent — when [period] is `custom`.
class DashboardRange extends Equatable {
  static const String thisWeek = 'this_week';
  static const String thisMonth = 'this_month';
  static const String custom = 'custom';

  final String period;
  final DateTime? start;
  final DateTime? end;

  const DashboardRange({this.period = thisMonth, this.start, this.end});

  /// A `custom` window. Normalizes to date-only values so the label and the
  /// `start_date`/`end_date` query params never carry a time component, and
  /// swaps reversed bounds rather than sending a range the API would reject.
  factory DashboardRange.between(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    final reversed = b.isBefore(a);
    return DashboardRange(
      period: custom,
      start: reversed ? b : a,
      end: reversed ? a : b,
    );
  }

  bool get isCustom => period == custom;

  /// True once a custom window has both bounds — i.e. it can be requested.
  bool get isComplete => !isCustom || (start != null && end != null);

  /// Days covered by a custom window (inclusive); null for the named periods.
  int? get spanInDays => (start == null || end == null)
      ? null
      : end!.difference(start!).inDays + 1;

  /// Conversion-trend bucket size for this window. The API keeps `granularity`
  /// independent of `period`, so it's the client's job to pick a bucket that
  /// leaves the trend line with more than one point to draw.
  String get granularity {
    if (isCustom) {
      final days = spanInDays ?? 0;
      if (days <= 21) return 'daily';
      if (days <= 120) return 'weekly';
      return 'monthly';
    }
    // A week fits daily buckets; a month reads better as ~4 weekly ones than
    // as the single bucket `monthly` would collapse it to.
    return period == thisWeek ? 'daily' : 'weekly';
  }

  @override
  List<Object?> get props => [period, start, end];
}
