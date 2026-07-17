import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';

/// Lead repository interface — domain layer
abstract class LeadRepository {
  Future<Either<Failure, List<Lead>>> getLeads({
    String? search,
    String? status,
    String? tier,
    String? owner,
    String? source,
    int page,
    int pageSize,
  });

  Future<Either<Failure, Lead>> getLeadById(String id);
  Future<Either<Failure, Lead>> createLead(Lead lead);
  Future<Either<Failure, Lead>> updateLead(Lead lead);
  Future<Either<Failure, bool>> checkDuplicate(String email);
  Future<Either<Failure, String>> convertToAccount(String leadId);
}

/// Datasource interface for the data layer
abstract class LeadRemoteDataSource {
  Future<List<Lead>> getLeads({
    String? search,
    String? status,
    String? tier,
    String? owner,
    String? source,
    int page,
    int pageSize,
  });
  Future<Lead> getLeadById(String id);
  Future<Lead> createLead(Lead lead);
  Future<Lead> updateLead(Lead lead);
  Future<bool> checkDuplicate(String email);
  Future<String> convertToAccount(String leadId);
}
