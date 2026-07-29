import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) the whole dashboard. Omit [period] to keep the current one.
class DashboardLoadRequested extends DashboardEvent {
  final String? period;
  const DashboardLoadRequested({this.period});

  @override
  List<Object?> get props => [period];
}
