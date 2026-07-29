import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_model.dart';

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final DioClient dioClient;

  DashboardRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<DashboardData> getDashboard({
    String period = 'this_month',
    String granularity = 'monthly',
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.dashboard,
        queryParameters: {
          'period': period,
          'granularity': granularity,
          'limit': limit,
          'offset': offset,
        },
      );
      return dashboardFromJson(response.data as Map<String, dynamic>);
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
