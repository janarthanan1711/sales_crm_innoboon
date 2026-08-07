import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../contacts/data/models/contact_model.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/data/models/deal_model.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_activity.dart';
import '../../domain/entities/account_overview.dart';
import '../../domain/repositories/account_repository.dart';
import '../models/account_activity_model.dart';
import '../models/account_model.dart';
import '../models/account_overview_model.dart';

/// Real API implementation of AccountRemoteDataSource — talks to
/// `saleshub`'s `/accounts` router. The backend supports `owner_id`, `tier`,
/// `industry`, `search` and pagination as server-side query params.
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  final DioClient _dioClient;

  AccountRemoteDataSourceImpl(this._dioClient);

  @override
  Future<({List<Account> items, int total})> getAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accounts,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (tier != null && tier.isNotEmpty && tier != 'All') 'tier': tier,
          if (industry != null && industry.isNotEmpty && industry != 'All')
            'industry': industry,
          'owner_id': ?ownerId,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>)
          .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, total: data['total'] as int? ?? items.length);
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
    List<AccountContactDraft>? contacts,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.accounts,
        data: AccountModel.toCreateJson(
          company: company,
          domain: domain,
          tier: tier,
          ownerId: ownerId,
          industry: industry,
          city: city,
          description: description,
          linkedinUrl: linkedinUrl,
          contacts: contacts,
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
          'company': ?company,
          'domain': ?domain,
          'tier': ?tier,
          'owner_id': ?ownerId,
          'industry': ?industry,
          'city': ?city,
          'description': ?description,
          'linkedin_url': ?linkedinUrl,
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
      // `GET /accounts/{id}/deals` returns full DealRead objects — unlike the
      // overview's `active_deals`, which only carry id/name/stage_id/value.
      final response = await _dioClient.get(
        ApiEndpoints.accountDeals(accountId),
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => DealModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<AccountOverview> getAccountOverview(String accountId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accountOverview(accountId),
      );
      return accountOverviewFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<AccountActivity>> listActivities(
    String accountId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.accountActivities(accountId),
        queryParameters: {
          if (types != null && types.isNotEmpty) 'types': types,
          if (dateFrom != null) 'date_from': _formatDate(dateFrom),
          if (dateTo != null) 'date_to': _formatDate(dateTo),
        },
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => accountActivityFromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<AccountActivity> logActivity(
    String accountId, {
    required String type,
    required String note,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.accountActivities(accountId),
        data: {'type': type, 'note': note},
      );
      return accountActivityFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<AccountActivity> updateActivity(
    String accountId,
    String activityId, {
    String? type,
    String? note,
  }) async {
    try {
      final response = await _dioClient.patch(
        ApiEndpoints.accountActivityById(accountId, activityId),
        data: {'type': ?type, 'note': ?note},
      );
      return accountActivityFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteActivity(String accountId, String activityId) async {
    try {
      await _dioClient.delete(
        ApiEndpoints.accountActivityById(accountId, activityId),
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Uint8List> exportAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
  }) async {
    try {
      final response = await _dioClient.get<List<int>>(
        ApiEndpoints.accounts,
        queryParameters: {
          'to_export': true,
          if (search != null && search.isNotEmpty) 'search': search,
          if (tier != null && tier.isNotEmpty && tier != 'All') 'tier': tier,
          if (industry != null && industry.isNotEmpty && industry != 'All')
            'industry': industry,
          'owner_id': ?ownerId,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Uint8List> exportAccount(String id) async {
    try {
      final response = await _dioClient.get<List<int>>(
        ApiEndpoints.accountById(id),
        queryParameters: {'to_export': true},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      await _dioClient.delete(ApiEndpoints.accountById(id));
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
