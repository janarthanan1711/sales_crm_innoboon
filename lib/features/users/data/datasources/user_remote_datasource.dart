import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/owner_user.dart';
import '../models/owner_user_model.dart';

/// Interface for the users remote datasource.
abstract class UserRemoteDataSource {
  Future<List<OwnerUser>> getUsers({
    int? roleId,
    bool? isActive,
    String? status,
    String? search,
  });
  Future<OwnerUser> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required int roleId,
  });
  Future<void> deleteUser(int id);
}

/// Real API implementation — calls `GET /users`, `POST /users`,
/// `DELETE /users/{id}`.
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final DioClient dioClient;

  UserRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<OwnerUser>> getUsers({
    int? roleId,
    bool? isActive,
    String? status,
    String? search,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.users,
        queryParameters: {
          if (roleId != null) 'role_id': roleId,
          if (isActive != null) 'is_active': isActive,
          if (status != null) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data as List<dynamic>;
      return data
          .map((json) => OwnerUserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<OwnerUser> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required int roleId,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.users,
        data: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role_id': roleId,
        },
      );
      return OwnerUserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteUser(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.userById('$id'));
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  Exception _normalize(DioException e) {
    final normalized = e.error;
    if (normalized is Exception) return normalized;
    return ServerException(
      message: e.message ?? 'Failed to fetch users',
      statusCode: e.response?.statusCode,
    );
  }
}
