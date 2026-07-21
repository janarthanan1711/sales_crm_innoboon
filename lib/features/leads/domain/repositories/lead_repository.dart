import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
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
}
