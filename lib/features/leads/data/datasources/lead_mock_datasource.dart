import 'package:uuid/uuid.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/data/datasources/account_mock_datasource.dart';

/// Mock datasource with realistic demo data
class LeadMockDataSource implements LeadRemoteDataSource {
  static final List<Lead> _mockLeads = [
    Lead(
      id: 'lead_001',
      companyName: 'Nexbridge Tech',
      contactName: 'Karthick Selvam',
      email: 'karthick@nexbridge.io',
      phone: '+91 98765 43210',
      source: 'LinkedIn',
      status: 'Contacted',
      owner: 'Sarah Jenkins',
      website: 'nexbridge.io',
      industry: 'IT Services',
      notes: 'Interested in cloud migration services',
      createdAt: DateTime(2024, 8, 15),
      lastContactedAt: DateTime(2024, 9, 10),
    ),
    Lead(
      id: 'lead_002',
      companyName: 'Cloudverge Solutions',
      contactName: 'Vishnu Priya',
      email: 'vishnu@cloudverge.com',
      phone: '+91 87654 32109',
      source: 'Referral',
      status: 'New',
      owner: 'M. Chen',
      website: 'cloudverge.com',
      industry: 'SaaS',
      notes: 'Referred by Nexbridge Tech CEO',
      createdAt: DateTime(2024, 9, 1),
    ),
    Lead(
      id: 'lead_003',
      companyName: 'Pixelforge Labs',
      contactName: 'Janarthanan R',
      email: 'jan@pixelforge.in',
      phone: '+91 76543 21098',
      source: 'Website',
      status: 'Contacted',
      owner: 'Sarah Jenkins',
      website: 'pixelforge.in',
      industry: 'Design & Media',
      notes: 'Downloaded whitepaper on UX design',
      createdAt: DateTime(2024, 8, 20),
      lastContactedAt: DateTime(2024, 9, 5),
    ),
    Lead(
      id: 'lead_004',
      companyName: 'Bright Orbit Inc',
      contactName: 'Shafeek Ahmed',
      email: 'shafeek@brightorbit.com',
      phone: '+91 65432 10987',
      source: 'Cold Outreach',
      status: 'New',
      owner: 'Shafeek Ahmed',
      website: 'brightorbit.com',
      industry: 'E-commerce',
      createdAt: DateTime(2024, 9, 8),
    ),
    Lead(
      id: 'lead_005',
      companyName: 'DataSpire Analytics',
      contactName: 'Karthick R',
      email: 'karthick@dataspire.co',
      phone: '+91 54321 09876',
      source: 'Apollo',
      status: 'Contacted',
      owner: 'Karthick Selvam',
      website: 'dataspire.co',
      industry: 'Data & Analytics',
      notes: 'Looking for BI dashboard development',
      createdAt: DateTime(2024, 7, 25),
      lastContactedAt: DateTime(2024, 9, 12),
    ),
    Lead(
      id: 'lead_006',
      companyName: 'TechCorp India',
      contactName: 'Rajesh Kumar',
      email: 'rajesh@techcorp.in',
      phone: '+91 43210 98765',
      source: 'Conference',
      status: 'Contacted',
      owner: 'Sarah Jenkins',
      website: 'techcorp.in',
      industry: 'IT Services',
      notes: 'Met at TechSummit 2024, enterprise deal potential',
      createdAt: DateTime(2024, 8, 1),
      lastContactedAt: DateTime(2024, 9, 14),
    ),
    Lead(
      id: 'lead_007',
      companyName: 'FinTrack Systems',
      contactName: 'Priya Sharma',
      email: 'priya@fintrack.io',
      phone: '+91 32109 87654',
      source: 'Lusha',
      status: 'New',
      owner: 'M. Chen',
      industry: 'FinTech',
      createdAt: DateTime(2024, 9, 12),
    ),
    Lead(
      id: 'lead_008',
      companyName: 'MedSync Health',
      contactName: 'Dr. Arjun Nair',
      email: 'arjun@medsync.health',
      phone: '+91 21098 76543',
      source: 'Referral',
      status: 'Contacted',
      owner: 'Sarah Jenkins',
      industry: 'HealthTech',
      notes: 'HIPAA compliant solution needed',
      createdAt: DateTime(2024, 7, 10),
      lastContactedAt: DateTime(2024, 9, 15),
    ),
    Lead(
      id: 'lead_009',
      companyName: 'EduLearn Plus',
      contactName: 'Sneha Menon',
      email: 'sneha@edulearn.co',
      source: 'Website',
      status: 'Junk',
      owner: 'Karthick Selvam',
      industry: 'EdTech',
      notes: 'Budget too low for our minimum engagement',
      createdAt: DateTime(2024, 8, 28),
      lastContactedAt: DateTime(2024, 9, 2),
    ),
    Lead(
      id: 'lead_010',
      companyName: 'GreenStack Energy',
      contactName: 'Amir Hussain',
      email: 'amir@greenstack.energy',
      phone: '+91 10987 65432',
      source: 'Partner',
      status: 'Contacted',
      owner: 'M. Chen',
      website: 'greenstack.energy',
      industry: 'Manufacturing',
      notes: 'IoT monitoring platform needed',
      createdAt: DateTime(2024, 8, 5),
      lastContactedAt: DateTime(2024, 9, 11),
    ),
    Lead(
      id: 'lead_011',
      companyName: 'UrbanNest Realty',
      contactName: 'Deepa Krishnan',
      email: 'deepa@urbannest.co',
      source: 'LinkedIn',
      status: 'New',
      owner: 'Sarah Jenkins',
      industry: 'Real Estate',
      createdAt: DateTime(2024, 9, 14),
    ),
    Lead(
      id: 'lead_012',
      companyName: 'Consultify Group',
      contactName: 'Ravi Patel',
      email: 'ravi@consultify.com',
      phone: '+91 98765 11111',
      source: 'HubSpot Import',
      status: 'Contacted',
      owner: 'Shafeek Ahmed',
      industry: 'Consulting',
      createdAt: DateTime(2024, 8, 18),
      lastContactedAt: DateTime(2024, 9, 6),
    ),
  ];

  @override
  Future<List<Lead>> getLeads({
    String? search,
    String? status,
    String? tier,
    String? owner,
    String? source,
    int page = 1,
    int pageSize = 25,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    var filtered = List<Lead>.from(_mockLeads);

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where(
            (l) =>
                l.companyName.toLowerCase().contains(q) ||
                l.contactName.toLowerCase().contains(q) ||
                l.email.toLowerCase().contains(q),
          )
          .toList();
    }
    if (status != null && status.isNotEmpty && status != 'All') {
      filtered = filtered.where((l) => l.status == status).toList();
    }
    if (tier != null && tier.isNotEmpty && tier != 'All') {
      filtered = filtered.where((l) => l.tier == tier).toList();
    }
    if (owner != null && owner.isNotEmpty && owner != 'All') {
      filtered = filtered.where((l) => l.owner == owner).toList();
    }
    if (source != null && source.isNotEmpty && source != 'All') {
      filtered = filtered.where((l) => l.source == source).toList();
    }

    // Sort by createdAt descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  @override
  Future<Lead> getLeadById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockLeads.firstWhere(
      (l) => l.id == id,
      orElse: () => throw Exception('Lead not found'),
    );
  }

  @override
  Future<Lead> createLead(Lead lead) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newLead = lead.copyWith(
      id: 'lead_${const Uuid().v4().substring(0, 8)}',
      createdAt: DateTime.now(),
    );
    _mockLeads.insert(0, newLead);
    return newLead;
  }

  @override
  Future<Lead> updateLead(Lead lead) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockLeads.indexWhere((l) => l.id == lead.id);
    if (index == -1) throw Exception('Lead not found');
    _mockLeads[index] = lead;
    return lead;
  }

  @override
  Future<bool> checkDuplicate(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLeads.any((l) => l.email.toLowerCase() == email.toLowerCase());
  }

  @override
  Future<String> convertToAccount(String leadId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final lead = _mockLeads.firstWhere((l) => l.id == leadId);

    // Create a new account from the lead data
    final newAccount = Account(
      id: 'acc_${lead.companyName.toLowerCase().replaceAll(' ', '_')}',
      companyName: lead.companyName,
      domain:
          lead.website ??
          '${lead.companyName.toLowerCase().replaceAll(' ', '')}.com',
      industry: lead.industry ?? 'Other',
      tier: 'Not Applicable', // Tier is set during conversion form submission
      primaryOwner: lead.owner ?? 'Unassigned',
      description: lead.notes ?? 'Converted from lead: ${lead.contactName}',
      contacts: [],
      activeDealsCount: 0,
      createdAt: DateTime.now(),
    );

    // Add the account to the mock database
    final accountDataSource = AccountMockDataSource();
    await accountDataSource.createAccount(newAccount);

    return newAccount.id;
  }
}
