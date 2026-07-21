import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';

class RoleRemoteDataSourceImpl implements RoleRemoteDataSource {
  final DioClient dioClient;

  RoleRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<Permission>> getPermissions() async {
    try {
      final response = await dioClient.get(ApiEndpoints.permissions);
      final data = response.data as List<dynamic>;
      return data.map((e) => Permission.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<List<Role>> getRoles() async {
    try {
      final response = await dioClient.get(ApiEndpoints.roles);
      final data = response.data as List<dynamic>;
      return data.map((e) => Role.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Role> createRole({
    required String name,
    String? description,
    required List<int> permissionIds,
  }) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.roles,
        data: {
          'name': name,
          'description': description,
          'permission_ids': permissionIds,
        },
      );
      return Role.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<Role> updateRole(
    int id, {
    String? name,
    String? description,
    List<int>? permissionIds,
  }) async {
    try {
      final response = await dioClient.patch(
        ApiEndpoints.roleById('$id'),
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (permissionIds != null) 'permission_ids': permissionIds,
        },
      );
      return Role.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> deleteRole(int id) async {
    try {
      await dioClient.delete(ApiEndpoints.roleById('$id'));
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
