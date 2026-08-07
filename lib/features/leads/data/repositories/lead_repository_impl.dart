import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_import_result.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/usecases/lead_upsert_params.dart';

class LeadRepositoryImpl implements LeadRepository {
  final LeadRemoteDataSource remoteDataSource;

  LeadRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({List<Lead> items, int total})>> getLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getLeads(
        ownerId: ownerId,
        source: source,
        status: status,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> getLeadById(int id) async {
    try {
      return Right(await remoteDataSource.getLeadById(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead(LeadUpsertParams params) async {
    try {
      return Right(await remoteDataSource.createLead(params));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLead(
    int id,
    LeadUpsertParams params,
  ) async {
    try {
      return Right(await remoteDataSource.updateLead(id, params));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> setFavourite(int id, bool isFavourite) async {
    try {
      return Right(await remoteDataSource.setFavourite(id, isFavourite));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLead(int id) async {
    try {
      await remoteDataSource.deleteLead(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> convertToAccount(
    int leadId, {
    String? tier,
    int? ownerId,
  }) async {
    try {
      return Right(
        await remoteDataSource.convertToAccount(
          leadId,
          tier: tier,
          ownerId: ownerId,
        ),
      );
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeadActivity>> logActivity(
    int leadId, {
    required String type,
    required String note,
  }) async {
    try {
      final activity = await remoteDataSource.logActivity(
        leadId,
        type: type,
        note: note,
      );
      return Right(activity);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeadActivity>>> listActivities(
    int leadId, {
    List<String>? types,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final activities = await remoteDataSource.listActivities(
        leadId,
        types: types,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      return Right(activities);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeadActivity>> updateActivity(
    int leadId,
    int activityId, {
    String? type,
    String? note,
  }) async {
    try {
      final activity = await remoteDataSource.updateActivity(
        leadId,
        activityId,
        type: type,
        note: note,
      );
      return Right(activity);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteActivity(
    int leadId,
    int activityId,
  ) async {
    try {
      await remoteDataSource.deleteActivity(leadId, activityId);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, LeadImportResult>> importLeads({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final result = await remoteDataSource.importLeads(
        bytes: bytes,
        filename: filename,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> downloadImportTemplate({
    String format = 'xlsx',
  }) async {
    try {
      final bytes = await remoteDataSource.downloadImportTemplate(
        format: format,
      );
      return Right(bytes);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportLeads({
    int? ownerId,
    String? source,
    String? status,
    String? search,
  }) async {
    try {
      final bytes = await remoteDataSource.exportLeads(
        ownerId: ownerId,
        source: source,
        status: status,
        search: search,
      );
      return Right(bytes);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> exportLead(int id) async {
    try {
      return Right(await remoteDataSource.exportLead(id));
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
