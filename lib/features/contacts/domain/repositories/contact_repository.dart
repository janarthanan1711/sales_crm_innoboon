import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';

abstract class ContactRepository {
  Future<Either<Failure, Contact>> getContactById(int id);
  Future<Either<Failure, Contact>> createContact({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    required int accountId,
  });
  Future<Either<Failure, Contact>> updateContact(
    int id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
  });
  Future<Either<Failure, void>> deleteContact(int id);
}

abstract class ContactRemoteDataSource {
  Future<Contact> getContactById(int id);
  Future<Contact> createContact({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    required int accountId,
  });
  Future<Contact> updateContact(
    int id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
  });
  Future<void> deleteContact(int id);
}
