import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsParams extends Equatable {
  final bool unreadOnly;
  final NotificationType? type;
  final int limit;
  final int offset;

  const GetNotificationsParams({
    this.unreadOnly = false,
    this.type,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [unreadOnly, type, limit, offset];
}

class GetNotificationsUseCase
    implements UseCase<({List<AppNotification> items, int total}), GetNotificationsParams> {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, ({List<AppNotification> items, int total})>> call(GetNotificationsParams params) =>
      repository.getNotifications(
        unreadOnly: params.unreadOnly,
        type: params.type,
        limit: params.limit,
        offset: params.offset,
      );
}

class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  final NotificationRepository repository;
  GetUnreadCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) => repository.getUnreadCount();
}

class MarkNotificationReadUseCase implements UseCase<void, int> {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int notificationId) => repository.markAsRead(notificationId);
}

class MarkNotificationUnreadUseCase implements UseCase<void, int> {
  final NotificationRepository repository;
  MarkNotificationUnreadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int notificationId) => repository.markAsUnread(notificationId);
}

/// Marks every unread notification as read (doc §9.4 — omitted `ids`).
class MarkAllNotificationsReadUseCase implements UseCase<int, NoParams> {
  final NotificationRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(NoParams params) => repository.markManyAsRead(null);
}

class MarkManyNotificationsReadUseCase implements UseCase<int, List<int>> {
  final NotificationRepository repository;
  MarkManyNotificationsReadUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(List<int> notificationIds) => repository.markManyAsRead(notificationIds);
}

class DeleteNotificationsUseCase implements UseCase<int, List<int>> {
  final NotificationRepository repository;
  DeleteNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(List<int> notificationIds) => repository.deleteNotifications(notificationIds);
}
