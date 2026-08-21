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
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<OwnerUser> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required int roleId,
  });
  Future<void> deleteUser(int id, {bool permanent = false});
  Future<void> activateUser(int id);
  Future<OwnerUser> reinviteUser(int id);
  Future<OwnerUser> updateUserRole(int id, int roleId);
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
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.users,
        queryParameters: {
          'role_id': ?roleId,
          'is_active': ?isActive,
          'status': ?status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (dateFrom != null) 'date_from': _formatDate(dateFrom),
          if (dateTo != null) 'date_to': _formatDate(dateTo),
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
  Future<void> deleteUser(int id, {bool permanent = false}) async {
    try {
      await dioClient.delete(
        ApiEndpoints.userById('$id'),
        queryParameters: permanent ? {'permanent': true} : null,
      );
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> activateUser(int id) async {
    try {
      await dioClient.post('${ApiEndpoints.userById('$id')}/activate');
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<OwnerUser> reinviteUser(int id) async {
    try {
      final response = await dioClient.post(
        '${ApiEndpoints.userById('$id')}/reinvite',
      );
      return OwnerUserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<OwnerUser> updateUserRole(int id, int roleId) async {
    try {
      final response = await dioClient.patch(
        '${ApiEndpoints.userById('$id')}/role',
        data: {'role_id': roleId},
      );
      return OwnerUserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
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
