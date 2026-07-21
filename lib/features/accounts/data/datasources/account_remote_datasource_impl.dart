import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../contacts/data/models/contact_model.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/data/models/deal_model.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

/// Real API implementation of AccountRemoteDataSource — talks to
/// `saleshub`'s `/accounts` router. Note the backend has no server-side
/// `industry` filter (only `owner_id`/`tier`/`search`/pagination) — the
/// industry dropdown in the accounts list is applied client-side by the
/// bloc after this fetch.
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
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accounts,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (tier != null && tier.isNotEmpty && tier != 'All') 'tier': tier,
          'limit': 100,
          'offset': 0,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      return items
          .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Account> getAccountById(String id) async {
    try {
      final response = await _dioClient.get(ApiEndpoints.accountById(id));
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Account> createAccount({
    required String company,
    String? domain,
    required String tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.accounts,
        data: AccountModel.toJson(
          company: company,
          domain: domain,
          tier: tier,
          ownerId: ownerId,
          industry: industry,
          city: city,
          description: description,
          linkedinUrl: linkedinUrl,
        ),
      );
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Account> updateAccount(
    String id, {
    String? company,
    String? domain,
    String? tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
  }) async {
    try {
      final response = await _dioClient.patch(
        ApiEndpoints.accountById(id),
        data: {
          if (company != null) 'company': company,
          if (domain != null) 'domain': domain,
          if (tier != null) 'tier': tier,
          if (ownerId != null) 'owner_id': ownerId,
          if (industry != null) 'industry': industry,
          if (city != null) 'city': city,
          if (description != null) 'description': description,
          if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
        },
      );
      return AccountModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<Contact>> getAccountContacts(String accountId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accountContacts(accountId),
        queryParameters: {'limit': 100, 'offset': 0},
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>;
      return items
          .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<Deal>> getAccountDeals(String accountId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accountDeals(accountId),
      );
      final items = response.data as List<dynamic>;
      return items
          .map((e) => DealModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
