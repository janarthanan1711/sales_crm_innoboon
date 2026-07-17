import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String accountId;
  final String dealId;
  final String stageName;
  final int stageOrder;
  final String itemText;
  final bool isCompleted;
  final String owningTeam;
  final String notes;
  final bool isConditional;
  final String conditionDescription;
  final DateTime? completedAt;
  final String? completedBy;

  const ChecklistItem({
    required this.id,
    this.accountId = '',
    this.dealId = '',
    required this.stageName,
    required this.stageOrder,
    required this.itemText,
    this.isCompleted = false,
    required this.owningTeam,
    this.notes = '',
    this.isConditional = false,
    this.conditionDescription = '',
    this.completedAt,
    this.completedBy,
  });

  ChecklistItem copyWith({
    String? id,
    String? accountId,
    String? dealId,
    String? stageName,
    int? stageOrder,
    String? itemText,
    bool? isCompleted,
    String? owningTeam,
    String? notes,
    bool? isConditional,
    String? conditionDescription,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      dealId: dealId ?? this.dealId,
      stageName: stageName ?? this.stageName,
      stageOrder: stageOrder ?? this.stageOrder,
      itemText: itemText ?? this.itemText,
      isCompleted: isCompleted ?? this.isCompleted,
      owningTeam: owningTeam ?? this.owningTeam,
      notes: notes ?? this.notes,
      isConditional: isConditional ?? this.isConditional,
      conditionDescription: conditionDescription ?? this.conditionDescription,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        dealId,
        stageName,
        stageOrder,
        itemText,
        isCompleted,
        owningTeam,
        notes,
        isConditional,
        conditionDescription,
        completedAt,
        completedBy,
      ];
}

class ChecklistStage extends Equatable {
  final String stageName;
  final int stageOrder;
  final List<ChecklistItem> items;

  const ChecklistStage({
    required this.stageName,
    required this.stageOrder,
    required this.items,
  });

  int get completedCount => items.where((i) => i.isCompleted).length;
  int get totalCount => items.length;
  double get completionPercentage => totalCount == 0 ? 0 : completedCount / totalCount;

  @override
  List<Object?> get props => [stageName, stageOrder, items];
}
