import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  final bool unreadOnly;
  final NotificationType? typeFilter;
  const NotificationLoadRequested({this.unreadOnly = false, this.typeFilter});
  @override
  List<Object?> get props => [unreadOnly, typeFilter];
}

class NotificationLoadMoreRequested extends NotificationEvent {
  const NotificationLoadMoreRequested();
}

class NotificationMarkedRead extends NotificationEvent {
  final int id;
  const NotificationMarkedRead(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationMarkedAllRead extends NotificationEvent {
  const NotificationMarkedAllRead();
}

class NotificationsBulkMarkReadRequested extends NotificationEvent {
  final List<int> ids;
  const NotificationsBulkMarkReadRequested(this.ids);
  @override
  List<Object?> get props => [ids];
}

class NotificationsBulkDeleteRequested extends NotificationEvent {
  final List<int> ids;
  const NotificationsBulkDeleteRequested(this.ids);
  @override
  List<Object?> get props => [ids];
}
