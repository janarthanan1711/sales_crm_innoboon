import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/contact.dart';
import '../../domain/repositories/contact_repository.dart';

class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource remoteDataSource;

  ContactRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Contact>> getContactById(int id) async {
    try {
      return Right(await remoteDataSource.getContactById(id));
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
}
