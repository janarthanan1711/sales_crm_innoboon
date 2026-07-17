import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Remote datasource interface for auth
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<String> refreshToken(String refreshToken);
  Future<void> logout(String refreshToken);
}

/// Real API implementation of AuthRemoteDataSource.
///
/// Backend has no `/me` endpoint (see app/api/v1/auth.py — only `/login`
/// exists) and the JWT carries only `sub` (user id) + `exp`, no user
/// profile or role claim. So identity is resolved by decoding `sub` from
/// the token, then looking that id up via `GET /users` (open to any
/// authenticated role).
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      final payload = _decodeJwtPayload(accessToken);
      final userId = int.tryParse(payload['sub']?.toString() ?? '');
      if (userId == null) {
        throw const ServerException(message: 'Invalid token: missing subject');
      }

      final usersResponse = await dioClient.get(
        ApiEndpoints.users,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final users = usersResponse.data as List<dynamic>;
      final match = users
          .cast<Map<String, dynamic>>()
          .firstWhere((u) => u['id'] == userId, orElse: () => const {});
      if (match.isEmpty) {
        throw const ServerException(message: 'Could not resolve current user');
      }

      return UserModel.fromJson({
        ...match,
        'access_token': accessToken,
        'refresh_token': refreshToken,
      });
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      return data['access_token'] as String;
    } on DioException catch (e) {
      throw _normalize(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await dioClient.post(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
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

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
