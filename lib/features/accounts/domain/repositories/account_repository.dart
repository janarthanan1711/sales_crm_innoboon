import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../entities/account.dart';
import '../entities/account_activity.dart';
import '../entities/account_overview.dart';

abstract class AccountRepository {
  Future<Either<Failure, ({List<Account> items, int total})>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
    int limit,
    int offset,
  });

  Future<Either<Failure, Account>> getAccountById(String id);

  Future<Either<Failure, Account>> createAccount({
    required String company,
    String? domain,
    required String tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
    List<AccountContactDraft>? contacts,
  });

  Future<Either<Failure, Account>> updateAccount(
    String id, {
    String? company,
    String? domain,
    String? tier,
    int? ownerId,
    String? industry,
    String? city,
    String? description,
    String? linkedinUrl,
  });

  Future<Either<Failure, List<Contact>>> getAccountContacts(String accountId);
  Future<Either<Failure, AccountOverview>> getAccountOverview(String accountId);

  Future<Either<Failure, List<AccountActivity>>> listActivities(
    String accountId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<Either<Failure, AccountActivity>> logActivity(
    String accountId, {
    required String type,
    required String note,
  });
  Future<Either<Failure, AccountActivity>> updateActivity(
    String accountId,
    String activityId, {
    String? type,
    String? note,
  });
  Future<Either<Failure, Unit>> deleteActivity(
    String accountId,
    String activityId,
  );

  /// Exports the filtered accounts as an `.xlsx` byte stream
  /// (`GET /accounts?to_export=true`). Role-scoped server-side.
  Future<Either<Failure, Uint8List>> exportAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
  });

  /// Exports one account as an `.xlsx` byte stream
  /// (`GET /accounts/{id}?to_export=true`) — sheets "Account", "Contacts",
  /// "Deals".
  Future<Either<Failure, Uint8List>> exportAccount(String id);
}

abstract class AccountRemoteDataSource {
  Future<({List<Account> items, int total})> getAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
    int limit,
    int offset,
  });
  Future<Account> getAccountById(String id);
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
  });
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
  });
  Future<List<Contact>> getAccountContacts(String accountId);
  Future<AccountOverview> getAccountOverview(String accountId);

  Future<List<AccountActivity>> listActivities(
    String accountId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<AccountActivity> logActivity(
    String accountId, {
    required String type,
    required String note,
  });
  Future<AccountActivity> updateActivity(
    String accountId,
    String activityId, {
    String? type,
    String? note,
  });
  Future<void> deleteActivity(String accountId, String activityId);

  Future<Uint8List> exportAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
  });
  Future<Uint8List> exportAccount(String id);
}
