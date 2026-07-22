import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../entities/account.dart';
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
}
