import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';

abstract class ContactRepository {
  /// `GET /contacts` — paginated list with optional filters. `ownerId`,
  /// `accountId` and `tier` match if ANY of a contact's linked accounts
  /// satisfies them; `isPrimary` keeps contacts primary on ≥1 account.
  Future<Either<Failure, ({List<Contact> items, int total})>> getContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
    int limit,
    int offset,
  });

  Future<Either<Failure, Contact>> getContactById(int id);

  /// `GET /contacts/{id}/overview` — Contact Detail Overview tab.
  Future<Either<Failure, ContactOverview>> getContactOverview(int id);

  /// `GET /contacts/{id}/deals` — every deal this contact is a stakeholder on.
  Future<Either<Failure, List<ContactDeal>>> getContactDeals(int id);

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
  Future<({List<Contact> items, int total})> getContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
    int limit,
    int offset,
  });
  Future<Contact> getContactById(int id);
  Future<ContactOverview> getContactOverview(int id);
  Future<List<ContactDeal>> getContactDeals(int id);
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
