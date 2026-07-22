import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';

abstract class ContactRepository {
  Future<Either<Failure, Contact>> getContactById(int id);

  /// Create-or-update a contact against an account (`POST
  /// /accounts/{accountId}/contacts`). Omit [contactId] to create a new
  /// contact; pass an existing id to update it and/or (un)set it primary for
  /// this account.
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
  });

  Future<Either<Failure, void>> deleteContact(int id);
}

abstract class ContactRemoteDataSource {
  Future<Contact> getContactById(int id);
  Future<Contact> upsertAccountContact({
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
  });
  Future<void> deleteContact(int id);
}
