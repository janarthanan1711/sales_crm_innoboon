import '../../domain/entities/checklist_item.dart';
import '../../domain/repositories/checklist_repository.dart';

class ChecklistMockDataSource implements ChecklistRemoteDataSource {
  // Generate some realistic dummy checklist data
  static final List<ChecklistItem> _mockItems = [
    // Discovery Phase
    const ChecklistItem(
      id: 'chk_1',
      dealId: 'deal_001',
      stageName: 'Discovery Phase',
      stageOrder: 1,
      itemText: 'Identify Key Stakeholders',
      isCompleted: true,
      owningTeam: 'Sales',
    ),
    const ChecklistItem(
      id: 'chk_2',
      dealId: 'deal_001',
      stageName: 'Discovery Phase',
      stageOrder: 1,
      itemText: 'Define Budget Constraints',
      isCompleted: true,
      owningTeam: 'Sales',
    ),
    const ChecklistItem(
      id: 'chk_3',
      dealId: 'deal_001',
      stageName: 'Discovery Phase',
      stageOrder: 1,
      itemText: 'Technical Requirements Document',
      isCompleted: false,
      owningTeam: 'Pre-Sales',
      notes: 'Waiting for client IT team to send architecture diagrams.',
    ),
    // Solution Design
    const ChecklistItem(
      id: 'chk_4',
      dealId: 'deal_001',
      stageName: 'Solution Design',
      stageOrder: 2,
      itemText: 'Architecture Review',
      isCompleted: false,
      owningTeam: 'Pre-Sales',
    ),
    const ChecklistItem(
      id: 'chk_5',
      dealId: 'deal_001',
      stageName: 'Solution Design',
      stageOrder: 2,
      itemText: 'Security Compliance Check',
      isCompleted: false,
      owningTeam: 'InfoSec',
      isConditional: true,
      conditionDescription: 'Only if deal involves cloud migration',
    ),
  ];

  @override
  Future<List<ChecklistStage>> getChecklistForDeal(String dealId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final items = _mockItems.where((i) => i.dealId == dealId).toList();
    if (items.isEmpty) return [];

    // Group by stage
    final Map<String, List<ChecklistItem>> grouped = {};
    for (var item in items) {
      grouped.putIfAbsent(item.stageName, () => []).add(item);
    }

    final stages = grouped.entries.map((entry) {
      return ChecklistStage(
        stageName: entry.key,
        stageOrder: entry.value.first.stageOrder,
        items: entry.value,
      );
    }).toList();

    stages.sort((a, b) => a.stageOrder.compareTo(b.stageOrder));
    return stages;
  }

  @override
  Future<List<ChecklistStage>> getChecklistForAccount(String accountId) async {
    // For simplicity in mock, just returning empty for account specific checklists
    return [];
  }

  @override
  Future<ChecklistItem> toggleItemStatus(String itemId, bool isCompleted) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockItems.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');
    
    final updated = _mockItems[index].copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? DateTime.now() : null,
      completedBy: isCompleted ? 'Current User' : null,
    );
    _mockItems[index] = updated;
    return updated;
  }

  @override
  Future<ChecklistItem> updateItemNotes(String itemId, String notes) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockItems.indexWhere((i) => i.id == itemId);
    if (index == -1) throw Exception('Item not found');
    
    final updated = _mockItems[index].copyWith(notes: notes);
    _mockItems[index] = updated;
    return updated;
  }
}
