import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Account>>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    String? owner,
  }) async {
    try {
      final accounts = await remoteDataSource.getAccounts(
        search: search,
        industry: industry,
        tier: tier,
        owner: owner,
      );
      return Right(accounts);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> getAccountById(String id) async {
    try {
      final account = await remoteDataSource.getAccountById(id);
      return Right(account);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> createAccount(Account account) async {
    try {
      final created = await remoteDataSource.createAccount(account);
      return Right(created);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> updateAccount(Account account) async {
    try {
      final updated = await remoteDataSource.updateAccount(account);
      return Right(updated);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> addContact(String accountId, Contact contact) async {
    try {
      final added = await remoteDataSource.addContact(accountId, contact);
      return Right(added);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
