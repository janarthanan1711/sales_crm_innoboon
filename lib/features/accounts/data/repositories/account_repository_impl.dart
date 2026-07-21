import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../domain/entities/account.dart';
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
      // The backend has no server-side industry filter — applied here.
      final filtered = (industry == null || industry.isEmpty || industry == 'All')
          ? accounts
          : accounts.where((a) => a.industry == industry).toList();
      return Right(filtered);
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
  Future<Either<Failure, Account>> createAccount({
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
      final created = await remoteDataSource.createAccount(
        company: company,
        domain: domain,
        tier: tier,
        ownerId: ownerId,
        industry: industry,
        city: city,
        description: description,
        linkedinUrl: linkedinUrl,
      );
      return Right(created);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final updated = await remoteDataSource.updateAccount(
        id,
        company: company,
        domain: domain,
        tier: tier,
        ownerId: ownerId,
        industry: industry,
        city: city,
        description: description,
        linkedinUrl: linkedinUrl,
      );
      return Right(updated);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> getAccountContacts(
    String accountId,
  ) async {
    try {
      return Right(await remoteDataSource.getAccountContacts(accountId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Deal>>> getAccountDeals(String accountId) async {
    try {
      return Right(await remoteDataSource.getAccountDeals(accountId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
