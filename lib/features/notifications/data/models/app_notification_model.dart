import '../../domain/entities/app_notification.dart';

AppNotification appNotificationFromJson(Map<String, dynamic> json) {
  return AppNotification(
    id: json['id'] as int,
    type: notificationTypeFromWire(json['type'] as String),
    title: json['title'] as String,
    body: json['body'] as String,
    isRead: json['is_read'] as bool? ?? false,
    readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    actorId: json['actor_id'] as int?,
    entityType: json['entity_type'] as String?,
    entityId: json['entity_id'] as int?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
