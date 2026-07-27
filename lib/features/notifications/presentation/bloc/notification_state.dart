import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int total;
  final int limit;
  final int unreadCount;
  final bool unreadOnly;
  final NotificationType? typeFilter;
  final bool isLoadingMore;

  const NotificationLoaded({
    required this.notifications,
    required this.total,
    required this.limit,
    required this.unreadCount,
    this.unreadOnly = false,
    this.typeFilter,
    this.isLoadingMore = false,
  });

  bool get hasMore => notifications.length < total;

  NotificationLoaded copyWith({
    List<AppNotification>? notifications,
    int? total,
    int? unreadCount,
    bool? isLoadingMore,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      limit: limit,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadOnly: unreadOnly,
      typeFilter: typeFilter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [notifications, total, limit, unreadCount, unreadOnly, typeFilter, isLoadingMore];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object?> get props => [message];
}
