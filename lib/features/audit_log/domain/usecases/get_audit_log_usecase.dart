import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/audit_log_entry.dart';
import '../repositories/audit_log_repository.dart';

class GetAuditLogParams extends Equatable {
  final String? tableName;
  final String? action;
  final int? actorId;
  final String? dateFrom; // YYYY-MM-DD
  final String? dateTo; // YYYY-MM-DD
  final int limit;
  final int offset;

  const GetAuditLogParams({
    this.tableName,
    this.action,
    this.actorId,
    this.dateFrom,
    this.dateTo,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
    tableName,
    action,
    actorId,
    dateFrom,
    dateTo,
    limit,
    offset,
  ];
}

class GetAuditLogUseCase {
  final AuditLogRepository repository;
  GetAuditLogUseCase(this.repository);

  Future<Either<Failure, ({List<AuditLogEntry> items, int total})>> call(
    GetAuditLogParams params,
  ) {
    return repository.getAuditLog(
      tableName: params.tableName,
      action: params.action,
      actorId: params.actorId,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
