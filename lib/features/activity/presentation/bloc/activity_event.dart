import 'package:equatable/equatable.dart';
import '../../domain/entities/activity.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();
  @override
  List<Object?> get props => [];
}

class ActivityLoadRequested extends ActivityEvent {
  final String entityType;
  final String entityId;
  const ActivityLoadRequested(this.entityType, this.entityId);
  @override
  List<Object?> get props => [entityType, entityId];
}

class ActivityFilterChanged extends ActivityEvent {
  final ActivityType? type;
  const ActivityFilterChanged(this.type);
  @override
  List<Object?> get props => [type];
}

class ActivityLogged extends ActivityEvent {
  final AppActivity activity;
  const ActivityLogged(this.activity);
  @override
  List<Object?> get props => [activity];
}
