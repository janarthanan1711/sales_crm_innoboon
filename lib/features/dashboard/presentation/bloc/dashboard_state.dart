import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  /// The period being loaded, so the period toggle stays highlighted while
  /// a switch is in flight.
  final String period;
  const DashboardLoading(this.period);

  @override
  List<Object?> get props => [period];
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final String period;
  const DashboardLoaded(this.data, this.period);

  @override
  List<Object?> get props => [data, period];
}

class DashboardError extends DashboardState {
  final String message;
  final String period;
  const DashboardError(this.message, this.period);

  @override
  List<Object?> get props => [message, period];
}
