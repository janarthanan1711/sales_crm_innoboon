import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

class NotificationMarkedRead extends NotificationEvent {
  final String id;
  const NotificationMarkedRead(this.id);
  @override
  List<Object?> get props => [id];
}

class NotificationMarkedAllRead extends NotificationEvent {
  const NotificationMarkedAllRead();
}
