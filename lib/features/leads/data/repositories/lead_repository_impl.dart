import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/lead.dart';
import '../../domain/repositories/lead_repository.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;

  LeadRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Lead>>> getLeads({
    String? search, String? status, String? tier,
    String? owner, String? source, int page = 1, int pageSize = 25,
  }) async {
    try {
      final leads = await remoteDataSource.getLeads(
        search: search, status: status, tier: tier,
        owner: owner, source: source, page: page, pageSize: pageSize,
      );
      return Right(leads);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(String id) async {
    try {
      return Right(await remoteDataSource.getLeadById(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead(Lead lead) async {
    try {
      return Right(await remoteDataSource.createLead(lead));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLead(Lead lead) async {
    try {
      return Right(await remoteDataSource.updateLead(lead));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkDuplicate(String email) async {
    try {
      return Right(await remoteDataSource.checkDuplicate(email));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> convertToAccount(String leadId) async {
    try {
      return Right(await remoteDataSource.convertToAccount(leadId));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
