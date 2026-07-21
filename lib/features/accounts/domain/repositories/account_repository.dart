import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/domain/entities/deal.dart';
import '../entities/account.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<Account>>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
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
  Future<Either<Failure, List<Deal>>> getAccountDeals(String accountId);
}

abstract class AccountRemoteDataSource {
  Future<List<Account>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
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
  Future<List<Deal>> getAccountDeals(String accountId);
}
