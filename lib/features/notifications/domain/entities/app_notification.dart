import 'package:equatable/equatable.dart';

/// Backend wire values: `task_overdue|deal_stage_changed|lead_assigned|new_lead`
/// (see doc §9.1). `task_overdue` entries are computed from overdue-follow-up
/// leads at read time — they carry a negative [AppNotification.id] and are not
/// stored rows, so they can't be marked read or deleted individually.
enum NotificationType { taskOverdue, dealStageChanged, leadAssigned, newLead }

const Map<String, String> notificationTypeLabels = {
  'task_overdue': 'Task Overdue',
  'deal_stage_changed': 'Deal Update',
  'lead_assigned': 'Lead Assigned',
  'new_lead': 'New Lead',
};

NotificationType notificationTypeFromWire(String wireValue) {
  switch (wireValue) {
    case 'deal_stage_changed':
      return NotificationType.dealStageChanged;
    case 'lead_assigned':
      return NotificationType.leadAssigned;
    case 'new_lead':
      return NotificationType.newLead;
    case 'task_overdue':
    default:
      return NotificationType.taskOverdue;
  }
}

String notificationTypeWireValue(NotificationType type) {
  switch (type) {
    case NotificationType.dealStageChanged:
      return 'deal_stage_changed';
    case NotificationType.leadAssigned:
      return 'lead_assigned';
    case NotificationType.newLead:
      return 'new_lead';
    case NotificationType.taskOverdue:
      return 'task_overdue';
  }
}

class AppNotification extends Equatable {
  final int id;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final int? actorId;
  final String? entityType;
  final int? entityId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.readAt,
    this.actorId,
    this.entityType,
    this.entityId,
    required this.createdAt,
  });

  /// Computed overdue-follow-up entries aren't persisted rows on the
  /// backend — negative ids can't be passed to the read/delete endpoints.
  bool get isComputed => id < 0;

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        isRead,
        readAt,
        actorId,
        entityType,
        entityId,
        createdAt,
      ];
}
