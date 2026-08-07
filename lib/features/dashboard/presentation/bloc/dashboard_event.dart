import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_range.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) the whole dashboard. Omit [range] to keep the current one
/// (e.g. the retry button after a failure).
class DashboardLoadRequested extends DashboardEvent {
  final DashboardRange? range;
  const DashboardLoadRequested({this.range});

  @override
  List<Object?> get props => [range];
}
