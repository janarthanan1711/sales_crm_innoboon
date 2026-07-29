import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../models/audit_log_entry_model.dart';

class AuditLogRemoteDataSourceImpl implements AuditLogRemoteDataSource {
  final DioClient dioClient;

  AuditLogRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<({List<AuditLogEntry> items, int total})> getAuditLog({
    String? tableName,
    String? action,
    int? actorId,
    String? dateFrom,
    String? dateTo,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.auditLog,
        queryParameters: {
          if (tableName != null && tableName.isNotEmpty)
            'table_name': tableName,
          if (action != null && action.isNotEmpty) 'action': action,
          'actor_id': ?actorId,
          if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
          'limit': limit,
          'offset': offset,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const [])
          .map((e) => auditLogEntryFromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, total: data['total'] as int? ?? items.length);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
