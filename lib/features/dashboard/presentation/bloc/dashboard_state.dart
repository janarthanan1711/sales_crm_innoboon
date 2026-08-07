import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_range.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  /// The window this state belongs to, so the period toggle stays in sync
  /// while loading and after a failure — not just once data arrives.
  DashboardRange get range => const DashboardRange();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  @override
  final DashboardRange range;
  const DashboardLoading(this.range);

  @override
  List<Object?> get props => [range];
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  @override
  final DashboardRange range;
  const DashboardLoaded(this.data, this.range);

  @override
  List<Object?> get props => [data, range];
}

class DashboardError extends DashboardState {
  final String message;
  @override
  final DashboardRange range;
  const DashboardError(this.message, this.range);

  @override
  List<Object?> get props => [message, range];
}
