import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/contact.dart';
import '../../domain/entities/contact_import_result.dart';
import '../../domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;

  ContactRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({List<Contact> items, int total})>> getContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return Right(await remoteDataSource.getContacts(
        ownerId: ownerId,
        accountId: accountId,
        tier: tier,
        isPrimary: isPrimary,
        search: search,
        limit: limit,
        offset: offset,
      ));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> getContactById(int id) async {
    try {
      return Right(await remoteDataSource.getContactById(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContactOverview>> getContactOverview(int id) async {
    try {
      return Right(await remoteDataSource.getContactOverview(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ContactDeal>>> getContactDeals(int id) async {
    try {
      return Right(await remoteDataSource.getContactDeals(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Contact>> upsertAccountContact({
    required int accountId,
    int? contactId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? alternatePhone,
    String? jobTitle,
    String? linkedinUrl,
    bool? isPrimary,
  }) async {
    try {
      final contact = await remoteDataSource.upsertAccountContact(
        accountId: accountId,
        contactId: contactId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        alternatePhone: alternatePhone,
        jobTitle: jobTitle,
        linkedinUrl: linkedinUrl,
        isPrimary: isPrimary,
      );
      return Right(contact);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteContact(int id) async {
    try {
      await remoteDataSource.deleteContact(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContactImportResult>> importContacts({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final result = await remoteDataSource.importContacts(
        bytes: bytes,
        filename: filename,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadImportTemplate({
    String format = 'xlsx',
  }) async {
    try {
      final bytes = await remoteDataSource.downloadImportTemplate(
        format: format,
      );
      return Right(bytes);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
  }) async {
    try {
      final bytes = await remoteDataSource.exportContacts(
        ownerId: ownerId,
        accountId: accountId,
        tier: tier,
        isPrimary: isPrimary,
        search: search,
      );
      return Right(bytes);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportContact(int id) async {
    try {
      return Right(await remoteDataSource.exportContact(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
