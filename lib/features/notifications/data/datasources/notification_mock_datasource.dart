import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationMockDataSource implements NotificationRemoteDataSource {
  final List<AppNotification> _mockNotifications = [
    AppNotification(
      id: 'notif_1',
      type: NotificationType.leadAssigned,
      title: 'New Lead Assigned',
      message: 'Alex Johnson has been assigned to you.',
      entityId: 'lead_002',
      entityType: 'Lead',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'notif_2',
      type: NotificationType.dealStageChanged,
      title: 'Deal Stage Updated',
      message: 'Q3 Enterprise Expansion moved to Proposals.',
      entityId: 'deal_001',
      entityType: 'Deal',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'notif_3',
      type: NotificationType.mention,
      title: 'You were mentioned',
      message: 'M. Chen mentioned you in a note on Cloudverge Solutions.',
      entityId: 'acc_cloudverge',
      entityType: 'Account',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = List<AppNotification>.from(_mockNotifications);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockNotifications.where((n) => !n.isRead).length;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _mockNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _mockNotifications[index] = _mockNotifications[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _mockNotifications.length; i++) {
      if (!_mockNotifications[i].isRead) {
        _mockNotifications[i] = _mockNotifications[i].copyWith(isRead: true);
      }
    }
  }
}
