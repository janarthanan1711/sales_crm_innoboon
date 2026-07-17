import 'package:uuid/uuid.dart';
import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityMockDataSource implements ActivityRemoteDataSource {
  static final List<AppActivity> _mockActivities = [
    AppActivity(
      id: 'act_1',
      type: ActivityType.meeting,
      title: 'Discovery Call',
      description: 'Discussed cloud migration strategy and timeline expectations.',
      entityType: 'Deal',
      entityId: 'deal_001',
      performedBy: 'Sarah Jenkins',
      performedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppActivity(
      id: 'act_2',
      type: ActivityType.email,
      title: 'Sent Proposal Draft',
      description: 'Emailed the V1 architecture proposal for review.',
      entityType: 'Deal',
      entityId: 'deal_001',
      performedBy: 'Sarah Jenkins',
      performedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    AppActivity(
      id: 'act_3',
      type: ActivityType.stageChange,
      title: 'Stage changed to Proposals',
      entityType: 'Deal',
      entityId: 'deal_001',
      performedBy: 'System',
      performedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    AppActivity(
      id: 'act_4',
      type: ActivityType.note,
      title: 'Client preference noted',
      description: 'Client prefers AWS over Azure due to existing credits.',
      entityType: 'Account',
      entityId: 'acc_nexbridge',
      performedBy: 'Sarah Jenkins',
      performedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<AppActivity>> getActivities(String entityType, String entityId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final filtered = _mockActivities.where((a) => a.entityType == entityType && a.entityId == entityId).toList();
    filtered.sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return filtered;
  }

  @override
  Future<AppActivity> logActivity(AppActivity activity) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final newActivity = AppActivity(
      id: 'act_${const Uuid().v4().substring(0, 8)}',
      type: activity.type,
      title: activity.title,
      description: activity.description,
      entityType: activity.entityType,
      entityId: activity.entityId,
      performedBy: activity.performedBy,
      performedAt: activity.performedAt,
    );
    _mockActivities.insert(0, newActivity);
    return newActivity;
  }
}
