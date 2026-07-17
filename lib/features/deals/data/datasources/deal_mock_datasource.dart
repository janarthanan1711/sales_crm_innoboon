import 'package:uuid/uuid.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/stakeholder.dart';
import '../../domain/repositories/deal_repository.dart';

class DealMockDataSource implements DealRemoteDataSource {
  static final List<Deal> _mockDeals = [
    Deal(
      id: 'deal_001',
      name: 'Q3 Enterprise Expansion',
      accountId: 'acc_nexbridge',
      accountName: 'Nexbridge Tech',
      contactId: 'con_001',
      contactName: 'Karthick Selvam',
      value: 4500000,
      currency: 'INR',
      stage: DealStage.proposals,
      expectedCloseDate: DateTime(2024, 9, 15),
      owner: 'Sarah Jenkins',
      tier: 'Strategic',
      description: 'Expanding their cloud infrastructure to support 10k new concurrent users.',
      stakeholders: const [
        Stakeholder(id: 'st_1', name: 'Karthick Selvam', role: 'CTO', email: 'karthick@nexbridge.io', dealId: 'deal_001', isPrimary: true),
      ],
      createdAt: DateTime(2024, 7, 1),
    ),
    Deal(
      id: 'deal_002',
      name: 'Data Migration Project',
      accountId: 'acc_cloudverge',
      accountName: 'Cloudverge Solutions',
      contactId: 'con_003',
      contactName: 'Vishnu Priya',
      value: 1250000,
      currency: 'INR',
      stage: DealStage.qualifiedToBuy,
      expectedCloseDate: DateTime(2024, 10, 10),
      owner: 'M. Chen',
      tier: 'Diamond',
      description: 'Migrating legacy databases to AWS.',
      createdAt: DateTime(2024, 7, 5),
    ),
    Deal(
      id: 'deal_003',
      name: 'Annual Support Contract',
      accountId: 'acc_techcorp',
      accountName: 'TechCorp India',
      value: 800000,
      currency: 'INR',
      stage: DealStage.evaluation,
      expectedCloseDate: DateTime(2024, 8, 31),
      owner: 'Sarah Jenkins',
      tier: 'Gold',
      createdAt: DateTime(2024, 6, 20),
    ),
  ];

  @override
  Future<List<Deal>> getDeals({
    String? owner,
    String? tier,
    DealStage? stage,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    var filtered = List<Deal>.from(_mockDeals);

    if (owner != null && owner.isNotEmpty && owner != 'All') {
      filtered = filtered.where((d) => d.owner == owner).toList();
    }
    if (tier != null && tier.isNotEmpty && tier != 'All') {
      filtered = filtered.where((d) => d.tier == tier).toList();
    }
    if (stage != null) {
      filtered = filtered.where((d) => d.stage == stage).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<Deal> getDealById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockDeals.firstWhere(
      (d) => d.id == id,
      orElse: () => throw Exception('Deal not found'),
    );
  }

  @override
  Future<Deal> createDeal(Deal deal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newDeal = deal.copyWith(
      id: 'deal_${const Uuid().v4().substring(0, 8)}',
      createdAt: DateTime.now(),
    );
    _mockDeals.insert(0, newDeal);
    return newDeal;
  }

  @override
  Future<Deal> updateDeal(Deal deal) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockDeals.indexWhere((d) => d.id == deal.id);
    if (index == -1) throw Exception('Deal not found');
    _mockDeals[index] = deal;
    return deal;
  }

  @override
  Future<Deal> updateDealStage(String id, DealStage stage) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockDeals.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Deal not found');
    
    final updatedDeal = _mockDeals[index].copyWith(stage: stage);
    _mockDeals[index] = updatedDeal;
    return updatedDeal;
  }

  @override
  Future<Stakeholder> addStakeholder(String dealId, Stakeholder stakeholder) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockDeals.indexWhere((d) => d.id == dealId);
    if (index == -1) throw Exception('Deal not found');
    
    final newStakeholder = Stakeholder(
      id: 'st_${const Uuid().v4().substring(0, 8)}',
      name: stakeholder.name,
      role: stakeholder.role,
      email: stakeholder.email,
      dealId: dealId,
      isPrimary: stakeholder.isPrimary,
    );
    
    final updatedDeal = _mockDeals[index].copyWith(
      stakeholders: [..._mockDeals[index].stakeholders, newStakeholder],
    );
    _mockDeals[index] = updatedDeal;
    return newStakeholder;
  }
}
