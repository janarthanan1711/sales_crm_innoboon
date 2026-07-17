import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account.dart';
import '../entities/contact.dart';

abstract class AccountRepository {
  Future<Either<Failure, List<Account>>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
  });
  
  Future<Either<Failure, Account>> getAccountById(String id);
  Future<Either<Failure, Account>> createAccount(Account account);
  Future<Either<Failure, Account>> updateAccount(Account account);
  Future<Either<Failure, Contact>> addContact(String accountId, Contact contact);
}

abstract class AccountRemoteDataSource {
  Future<List<Account>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
  });
  Future<Account> getAccountById(String id);
  Future<Account> createAccount(Account account);
  Future<Account> updateAccount(Account account);
  Future<Contact> addContact(String accountId, Contact contact);
}
