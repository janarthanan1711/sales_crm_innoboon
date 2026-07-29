import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
import '../entities/lead_import_result.dart';
import '../usecases/lead_upsert_params.dart';

/// Lead repository interface — domain layer
abstract class LeadRepository {
  Future<Either<Failure, ({List<Lead> items, int total})>> getLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  });

  Future<Either<Failure, Lead>> getLeadById(int id);
  Future<Either<Failure, Lead>> createLead(LeadUpsertParams params);
  Future<Either<Failure, Lead>> updateLead(int id, LeadUpsertParams params);
  Future<Either<Failure, void>> deleteLead(int id);

  /// Returns the new account's id — conversion is out of Week-1 scope for
  /// the (still-mocked) Account feature, so this deliberately doesn't model
  /// the full `AccountRead` response.
  Future<Either<Failure, int>> convertToAccount(
    int leadId, {
    String? tier,
    int? ownerId,
  });

  Future<Either<Failure, LeadActivity>> logActivity(
    int leadId, {
    required String type,
    required String note,
  });

  Future<Either<Failure, List<LeadActivity>>> listActivities(
    int leadId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<Either<Failure, LeadActivity>> updateActivity(
    int leadId,
    int activityId, {
    String? type,
    String? note,
  });

  Future<Either<Failure, void>> deleteActivity(int leadId, int activityId);

  /// Bulk-import leads from an uploaded `.csv`/`.xlsx` file. Returns a
  /// summary — HTTP is always 200, so partial failures live in the result.
  Future<Either<Failure, LeadImportResult>> importLeads({
    required Uint8List bytes,
    required String filename,
  });

  /// Downloads the sample import template as raw bytes. [format] is
  /// `'xlsx'` (default) or `'csv'`.
  Future<Either<Failure, Uint8List>> downloadImportTemplate({String format});

  /// Exports the filtered leads as an `.xlsx` byte stream
  /// (`GET /leads?to_export=true`). Role-scoped server-side.
  Future<Either<Failure, Uint8List>> exportLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
  });

  /// Exports one lead as an `.xlsx` byte stream
  /// (`GET /leads/{id}?to_export=true`) — sheets "Lead" and "Activities".
  Future<Either<Failure, Uint8List>> exportLead(int id);
}

/// Datasource interface for the data layer
abstract class LeadRemoteDataSource {
  Future<({List<Lead> items, int total})> getLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  });
  Future<Lead> getLeadById(int id);
  Future<Lead> createLead(LeadUpsertParams params);
  Future<Lead> updateLead(int id, LeadUpsertParams params);
  Future<void> deleteLead(int id);
  Future<int> convertToAccount(int leadId, {String? tier, int? ownerId});
  Future<LeadActivity> logActivity(int leadId, {required String type, required String note});
  Future<List<LeadActivity>> listActivities(
    int leadId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<LeadActivity> updateActivity(
    int leadId,
    int activityId, {
    String? type,
    String? note,
  });
  Future<void> deleteActivity(int leadId, int activityId);
  Future<LeadImportResult> importLeads({
    required Uint8List bytes,
    required String filename,
  });
  Future<Uint8List> downloadImportTemplate({String format});
  Future<Uint8List> exportLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
  });
  Future<Uint8List> exportLead(int id);
}
