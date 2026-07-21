import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, ({List<AppNotification> items, int total})>> getNotifications({
    bool unreadOnly = false,
    NotificationType? type,
    int limit = 20,
    int offset = 0,
  });
  Future<Either<Failure, int>> getUnreadCount();
  Future<Either<Failure, void>> markAsRead(int notificationId);

  /// Marks `notificationIds` as read, or every unread notification when
  /// `notificationIds` is null/omitted. Returns the number updated.
  Future<Either<Failure, int>> markManyAsRead(List<int>? notificationIds);

  /// Returns the number deleted.
  Future<Either<Failure, int>> deleteNotifications(List<int> notificationIds);
}

abstract class NotificationRemoteDataSource {
  Future<({List<AppNotification> items, int total})> getNotifications({
    bool unreadOnly = false,
    NotificationType? type,
    int limit = 20,
    int offset = 0,
  });
  Future<int> getUnreadCount();
  Future<void> markAsRead(int notificationId);
  Future<int> markManyAsRead(List<int>? notificationIds);
  Future<int> deleteNotifications(List<int> notificationIds);
}
