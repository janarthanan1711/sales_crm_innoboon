import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  final AuditLogRemoteDataSource remoteDataSource;

  AuditLogRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ({List<AuditLogEntry> items, int total})>>
  getAuditLog({
    String? tableName,
    String? action,
    int? actorId,
    String? dateFrom,
    String? dateTo,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final result = await remoteDataSource.getAuditLog(
        tableName: tableName,
        action: action,
        actorId: actorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
