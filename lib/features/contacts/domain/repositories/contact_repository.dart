import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';
import '../entities/contact_import_result.dart';

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

  /// `POST /contacts/import` — bulk-create standalone contacts from a filled
  /// `.csv`/`.xlsx`. Returns 200 even with per-row failures, so inspect
  /// [ContactImportResult.errors].
  Future<Either<Failure, ContactImportResult>> importContacts({
    required Uint8List bytes,
    required String filename,
  });

  /// `GET /contacts/import/template` — the sample file with the exact columns
  /// and one example row. [format] is `'xlsx'` (default) or `'csv'`.
  Future<Either<Failure, Uint8List>> downloadImportTemplate({String format});

  /// Exports the filtered contacts as an `.xlsx` byte stream
  /// (`GET /contacts?to_export=true`).
  Future<Either<Failure, Uint8List>> exportContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
  });

  /// Exports one contact as an `.xlsx` byte stream
  /// (`GET /contacts/{id}?to_export=true`) — sheets "Contact" and "Deals".
  Future<Either<Failure, Uint8List>> exportContact(int id);
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
  Future<ContactImportResult> importContacts({
    required Uint8List bytes,
    required String filename,
  });
  Future<Uint8List> downloadImportTemplate({String format});
  Future<Uint8List> exportContacts({
    int? ownerId,
    int? accountId,
    String? tier,
    bool? isPrimary,
    String? search,
  });
  Future<Uint8List> exportContact(int id);
}
