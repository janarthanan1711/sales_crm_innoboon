import 'package:equatable/equatable.dart';
import '../../domain/entities/activity.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {
  const ActivityInitial();
}

class ActivityLoading extends ActivityState {
  const ActivityLoading();
}

class ActivityLoaded extends ActivityState {
  final List<AppActivity> activities;
  final ActivityType? filterType;
  const ActivityLoaded(this.activities, {this.filterType});
  @override
  List<Object?> get props => [activities, filterType];
}

class ActivityError extends ActivityState {
  final String message;
  const ActivityError(this.message);
  @override
  List<Object?> get props => [message];
}
