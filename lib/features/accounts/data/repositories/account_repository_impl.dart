import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_activity.dart';
import '../../domain/entities/account_overview.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountRemoteDataSource remoteDataSource;

  AccountRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({List<Account> items, int total})>> getAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final page = await remoteDataSource.getAccounts(
        search: search,
        industry: industry,
        tier: tier,
        ownerId: ownerId,
        limit: limit,
        offset: offset,
      );
      return Right(page);
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
    List<AccountContactDraft>? contacts,
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
        contacts: contacts,
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
  Future<Either<Failure, AccountOverview>> getAccountOverview(
    String accountId,
  ) async {
    try {
      return Right(await remoteDataSource.getAccountOverview(accountId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AccountActivity>>> listActivities(
    String accountId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      return Right(await remoteDataSource.listActivities(
        accountId,
        types: types,
        dateFrom: dateFrom,
        dateTo: dateTo,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountActivity>> logActivity(
    String accountId, {
    required String type,
    required String note,
  }) async {
    try {
      return Right(await remoteDataSource.logActivity(
        accountId,
        type: type,
        note: note,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AccountActivity>> updateActivity(
    String accountId,
    String activityId, {
    String? type,
    String? note,
  }) async {
    try {
      return Right(await remoteDataSource.updateActivity(
        accountId,
        activityId,
        type: type,
        note: note,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteActivity(
    String accountId,
    String activityId,
  ) async {
    try {
      await remoteDataSource.deleteActivity(accountId, activityId);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportAccounts({
    String? search,
    String? industry,
    String? tier,
    int? ownerId,
  }) async {
    try {
      return Right(await remoteDataSource.exportAccounts(
        search: search,
        industry: industry,
        tier: tier,
        ownerId: ownerId,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportAccount(String id) async {
    try {
      return Right(await remoteDataSource.exportAccount(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
