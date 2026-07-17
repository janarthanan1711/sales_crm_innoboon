import 'package:equatable/equatable.dart';

enum ActivityType {
  call,
  email,
  meeting,
  note,
  stageChange,
  taskComplete
}

class AppActivity extends Equatable {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String entityType; // e.g., 'Lead', 'Account', 'Deal'
  final String entityId;
  final String performedBy;
  final DateTime performedAt;

  const AppActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    required this.entityType,
    required this.entityId,
    required this.performedBy,
    required this.performedAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        entityType,
        entityId,
        performedBy,
        performedAt,
      ];
}
