import 'package:equatable/equatable.dart';

enum NotificationType {
  leadAssigned,
  dealStageChanged,
  taskDue,
  mention,
  system
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? entityId; // ID of the related Lead, Deal, etc.
  final String? entityType;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.entityId,
    this.entityType,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    String? entityId,
    String? entityType,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        message,
        entityId,
        entityType,
        isRead,
        createdAt,
      ];
}
