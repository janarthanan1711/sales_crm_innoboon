import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

/// Create-or-update a contact on an account. Omit [contactId] to create;
/// pass it to update fields and/or toggle `isPrimary` for [accountId].
class UpsertAccountContactParams {
  final int accountId;
  final int? contactId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? alternatePhone;
  final String? jobTitle;
  final String? linkedinUrl;
  final bool? isPrimary;

  const UpsertAccountContactParams({
    required this.accountId,
    this.contactId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.alternatePhone,
    this.jobTitle,
    this.linkedinUrl,
    this.isPrimary,
  });
}

class UpsertAccountContactUseCase {
  final ContactRepository repository;
  UpsertAccountContactUseCase(this.repository);

  Future<Either<Failure, Contact>> call(UpsertAccountContactParams params) {
    return repository.upsertAccountContact(
      accountId: params.accountId,
      contactId: params.contactId,
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      phone: params.phone,
      alternatePhone: params.alternatePhone,
      jobTitle: params.jobTitle,
      linkedinUrl: params.linkedinUrl,
      isPrimary: params.isPrimary,
    );
  }
}

class DeleteContactUseCase {
  final ContactRepository repository;
  DeleteContactUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.deleteContact(id);
}
