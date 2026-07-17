import '../../../../core/network/dio_client.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final DioClient _dioClient;

  AccountRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<Account>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (industry != null && industry.isNotEmpty) queryParams['industry'] = industry;
    if (tier != null && tier.isNotEmpty) queryParams['tier'] = tier;
    if (owner != null && owner.isNotEmpty) queryParams['owner'] = owner;

    final response = await _dioClient.get(
      '/api/v1/accounts',
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic> && response.data['items'] != null) {
      final items = response.data['items'] as List;
      return items.map((e) => AccountModel.fromJson(e)).toList();
    } else if (response.data is List) {
      final items = response.data as List;
      return items.map((e) => AccountModel.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<Account> getAccountById(String id) async {
    final response = await _dioClient.get('/api/v1/accounts/$id');
    return AccountModel.fromJson(response.data);
  }

  @override
  Future<Account> createAccount(Account account) async {
    final response = await _dioClient.post(
      '/api/v1/accounts',
      data: (account as AccountModel).toJson(),
    );
    return AccountModel.fromJson(response.data);
  }

  @override
  Future<Account> updateAccount(Account account) async {
    final response = await _dioClient.put(
      '/api/v1/accounts/${account.id}',
      data: (account as AccountModel).toJson(),
    );
    return AccountModel.fromJson(response.data);
  }

  @override
  Future<Contact> addContact(String accountId, Contact contact) async {
    final response = await _dioClient.post(
      '/api/v1/accounts/$accountId/contacts',
      data: {
        'name': contact.name,
        'email': contact.email,
        'phone': contact.phone,
        'role': contact.role,
      },
    );
    return Contact(
      id: response.data['id']?.toString() ?? '',
      name: response.data['name'] ?? '',
      email: response.data['email'] ?? '',
      phone: response.data['phone'] ?? '',
      role: response.data['role'] ?? '',
      accountId: accountId,
    );
  }
}
