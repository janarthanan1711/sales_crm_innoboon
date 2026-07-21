import 'package:uuid/uuid.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/account_repository.dart';

class AccountMockDataSource implements AccountRemoteDataSource {
  static final List<Account> _mockAccounts = [
    Account(
      id: 'acc_nexbridge',
      companyName: 'Nexbridge Tech',
      domain: 'nexbridge.io',
      industry: 'IT Services',
      tier: 'Strategic',
      primaryOwner: 'Sarah Jenkins',
      description:
          'Enterprise IT services provider specializing in cloud migration and digital transformation.',
      activeDealsCount: 3,
      createdAt: DateTime(2024, 1, 15),
      contacts: const [
        Contact(
          id: 'con_001',
          name: 'Karthick Selvam',
          role: 'CTO',
          email: 'karthick@nexbridge.io',
          phone: '+91 98765 43210',
          isDecisionMaker: true,
          accountId: 'acc_nexbridge',
        ),
        Contact(
          id: 'con_002',
          name: 'Priya Rajan',
          role: 'VP Engineering',
          email: 'priya@nexbridge.io',
          isDecisionMaker: false,
          accountId: 'acc_nexbridge',
        ),
      ],
    ),
    Account(
      id: 'acc_cloudverge',
      companyName: 'Cloudverge Solutions',
      domain: 'cloudverge.com',
      industry: 'SaaS',
      tier: 'Diamond',
      primaryOwner: 'M. Chen',
      description: 'SaaS platform for multi-cloud management.',
      activeDealsCount: 1,
      createdAt: DateTime(2024, 3, 22),
      contacts: const [
        Contact(
          id: 'con_003',
          name: 'Vishnu Priya',
          role: 'Director of IT',
          email: 'vishnu@cloudverge.com',
          phone: '+91 87654 32109',
          isDecisionMaker: true,
          accountId: 'acc_cloudverge',
        ),
      ],
    ),
    Account(
      id: 'acc_pixelforge',
      companyName: 'Pixelforge Labs',
      domain: 'pixelforge.in',
      industry: 'Design & Media',
      tier: 'Silver',
      primaryOwner: 'Sarah Jenkins',
      description: 'Creative agency focusing on UX/UI design.',
      activeDealsCount: 0,
      createdAt: DateTime(2024, 5, 10),
      contacts: const [],
    ),
  ];

  @override
  Future<List<Account>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    var filtered = List<Account>.from(_mockAccounts);

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where(
            (a) =>
                a.companyName.toLowerCase().contains(q) ||
                a.domain.toLowerCase().contains(q),
          )
          .toList();
    }
    if (industry != null && industry.isNotEmpty && industry != 'All') {
      filtered = filtered.where((a) => a.industry == industry).toList();
    }
    if (tier != null && tier.isNotEmpty && tier != 'All') {
      filtered = filtered.where((a) => a.tier == tier).toList();
    }
    if (owner != null && owner.isNotEmpty && owner != 'All') {
      filtered = filtered.where((a) => a.primaryOwner == owner).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<Account> getAccountById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockAccounts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Account not found'),
    );
  }

  @override
  Future<Account> createAccount(Account account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newAccount = account.copyWith(
      id: 'acc_${const Uuid().v4().substring(0, 8)}',
      createdAt: DateTime.now(),
    );
    _mockAccounts.insert(0, newAccount);
    return newAccount;
  }

  @override
  Future<Account> updateAccount(Account account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockAccounts.indexWhere((a) => a.id == account.id);
    if (index == -1) throw Exception('Account not found');
    _mockAccounts[index] = account;
    return account;
  }

  @override
  Future<Contact> addContact(String accountId, Contact contact) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockAccounts.indexWhere((a) => a.id == accountId);
    if (index == -1) throw Exception('Account not found');

    final newContact = Contact(
      id: 'con_${const Uuid().v4().substring(0, 8)}',
      name: contact.name,
      role: contact.role,
      email: contact.email,
      phone: contact.phone,
      isDecisionMaker: contact.isDecisionMaker,
      accountId: accountId,
    );

    final updatedAccount = _mockAccounts[index].copyWith(
      contacts: [..._mockAccounts[index].contacts, newContact],
    );
    _mockAccounts[index] = updatedAccount;
    return newContact;
  }
}
