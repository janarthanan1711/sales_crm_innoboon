import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_range.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DashboardData> getDashboard({
    DashboardRange range = const DashboardRange(),
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.dashboard,
        queryParameters: {
          'period': range.period,
          // Only a `custom` period carries bounds; sending them alongside a
          // named period is at best ignored and at worst a 422.
          if (range.isCustom && range.start != null)
            'start_date': _formatDate(range.start!),
          if (range.isCustom && range.end != null)
            'end_date': _formatDate(range.end!),
          'granularity': range.granularity,
          'limit': limit,
          'offset': offset,
        },
      );
      return dashboardFromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  /// `YYYY-MM-DD`, the format the API's date query params expect.
  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
