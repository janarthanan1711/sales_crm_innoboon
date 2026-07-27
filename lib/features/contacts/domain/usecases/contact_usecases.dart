import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

/// Filters/pagination for the Contacts List screen.
class GetContactsParams extends Equatable {
  final int? ownerId;
  final int? accountId;
  final String? tier;
  final bool? isPrimary;
  final String? search;
  final int limit;
  final int offset;

  const GetContactsParams({
    this.ownerId,
    this.accountId,
    this.tier,
    this.isPrimary,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props =>
      [ownerId, accountId, tier, isPrimary, search, limit, offset];
}

class GetContactsUseCase {
  final ContactRepository repository;
  GetContactsUseCase(this.repository);

  Future<Either<Failure, ({List<Contact> items, int total})>> call(
    GetContactsParams params,
  ) {
    return repository.getContacts(
      ownerId: params.ownerId,
      accountId: params.accountId,
      tier: params.tier,
      isPrimary: params.isPrimary,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetContactOverviewUseCase {
  final ContactRepository repository;
  GetContactOverviewUseCase(this.repository);

  Future<Either<Failure, ContactOverview>> call(int id) =>
      repository.getContactOverview(id);
}

class GetContactDealsUseCase {
  final ContactRepository repository;
  GetContactDealsUseCase(this.repository);

  Future<Either<Failure, List<ContactDeal>>> call(int id) =>
      repository.getContactDeals(id);
}

class GetContactByIdUseCase {
  final ContactRepository repository;
  GetContactByIdUseCase(this.repository);

  Future<Either<Failure, Contact>> call(int id) =>
      repository.getContactById(id);
}

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
