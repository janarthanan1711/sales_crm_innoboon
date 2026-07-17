import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase implements UseCase<List<AppNotification>, NoParams> {
  final NotificationRepository repository;
  GetNotificationsUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<AppNotification>>> call(NoParams params) => 
      repository.getNotifications();
}

class GetUnreadCountUseCase implements UseCase<int, NoParams> {
  final NotificationRepository repository;
  GetUnreadCountUseCase(this.repository);
  
  @override
  Future<Either<Failure, int>> call(NoParams params) => 
      repository.getUnreadCount();
}

class MarkNotificationReadUseCase implements UseCase<void, String> {
  final NotificationRepository repository;
  MarkNotificationReadUseCase(this.repository);
  
  @override
  Future<Either<Failure, void>> call(String notificationId) => 
      repository.markAsRead(notificationId);
}

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  final NotificationRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);
  
  @override
  Future<Either<Failure, void>> call(NoParams params) => 
      repository.markAllAsRead();
}
