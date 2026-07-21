import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({List<AppNotification> items, int total})>> getNotifications({
    bool unreadOnly = false,
    NotificationType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final page = await remoteDataSource.getNotifications(
        unreadOnly: unreadOnly,
        type: type,
        limit: limit,
        offset: offset,
      );
      return Right(page);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      final count = await remoteDataSource.getUnreadCount();
      return Right(count);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> markManyAsRead(List<int>? notificationIds) async {
    try {
      final updated = await remoteDataSource.markManyAsRead(notificationIds);
      return Right(updated);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteNotifications(List<int> notificationIds) async {
    try {
      final deleted = await remoteDataSource.deleteNotifications(notificationIds);
      return Right(deleted);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
