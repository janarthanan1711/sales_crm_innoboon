import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../models/app_notification_model.dart';

/// Real API implementation of NotificationRemoteDataSource — talks to
/// `saleshub`'s `/notifications` router (see doc §9).
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<({List<AppNotification> items, int total})> getNotifications({
    bool unreadOnly = false,
    NotificationType? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.notifications,
        queryParameters: {
          'unread_only': unreadOnly,
          if (type != null) 'type': notificationTypeWireValue(type),
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((json) => appNotificationFromJson(json as Map<String, dynamic>))
          .toList();
      return (items: items, total: data['total'] as int);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await dioClient.get(ApiEndpoints.notificationsUnreadCount);
      return (response.data as Map<String, dynamic>)['unread_count'] as int;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> markAsRead(int notificationId) async {
    try {
      await dioClient.patch(ApiEndpoints.markNotificationRead('$notificationId'));
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<int> markManyAsRead(List<int>? notificationIds) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.notificationsReadAll,
        data: notificationIds != null ? {'ids': notificationIds} : {},
      );
      return (response.data as Map<String, dynamic>)['updated'] as int;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<int> deleteNotifications(List<int> notificationIds) async {
    try {
      final response = await dioClient.delete(
        ApiEndpoints.notifications,
        data: {'ids': notificationIds},
      );
      return (response.data as Map<String, dynamic>)['deleted'] as int;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
