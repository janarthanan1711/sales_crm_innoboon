import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/owner_user.dart';
import '../models/owner_user_model.dart';

/// Interface for the users remote datasource.
abstract class UserRemoteDataSource {
  Future<List<OwnerUser>> getUsers();
}

/// Real API implementation — calls `GET /users`.
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<OwnerUser>> getUsers() async {
    try {
      final response = await dioClient.get(ApiEndpoints.users);
      final data = response.data as List<dynamic>;
      return data
          .map((json) =>
              OwnerUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final normalized = e.error;
      if (normalized is Exception) throw normalized;
      throw ServerException(
        message: e.message ?? 'Failed to fetch users',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
