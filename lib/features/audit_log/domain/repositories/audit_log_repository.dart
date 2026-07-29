import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log_entry.dart';

abstract class AuditLogRepository {
  /// `GET /audit-log` — paginated. [dateFrom]/[dateTo] are plain `YYYY-MM-DD`
  /// dates (not timestamps). Requires the `audit_log.view` permission.
  Future<Either<Failure, ({List<AuditLogEntry> items, int total})>> getAuditLog({
    String? tableName,
    String? action,
    int? actorId,
    String? dateFrom,
    String? dateTo,
    int limit,
    int offset,
  });
}

abstract class AuditLogRemoteDataSource {
  Future<({List<AuditLogEntry> items, int total})> getAuditLog({
    String? tableName,
    String? action,
    int? actorId,
    String? dateFrom,
    String? dateTo,
    int limit,
    int offset,
  });
}
