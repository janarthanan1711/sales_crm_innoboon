import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Remote datasource interface for auth
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<String> refreshToken(String refreshToken);
}

/// Mock implementation — returns dummy user data
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    // Accept any email/password for demo
    if (password.length < 4) {
      throw Exception('Invalid credentials');
    }

    // Return mock user
    return UserModel(
      id: 'usr_001',
      name: 'Sarah Jenkins',
      email: email,
      role: 'sales_manager',
      avatarUrl: null,
      phone: '+91 98765 43210',
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Real API implementation of AuthRemoteDataSource
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String?;

        // Decode JWT token payload to extract user info if available
        final payload = _decodeJwtPayload(accessToken);

        final emailFromToken = payload['email'] as String? ?? payload['sub'] as String? ?? email;
        final nameFromToken = payload['name'] as String? ?? payload['username'] as String? ?? 'Sales Representative';
        final idFromToken = payload['id'] as String? ?? payload['sub'] as String? ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';
        // Some systems return role/roles in JWT. Fallback to sales_manager/sales_rep.
        final roleFromToken = payload['role'] as String? ?? payload['roles'] as String? ?? 'sales_manager';
        final avatarUrlFromToken = payload['avatar_url'] as String? ?? payload['avatar'] as String?;
        final phoneFromToken = payload['phone'] as String?;

        return UserModel(
          id: idFromToken,
          name: nameFromToken,
          email: emailFromToken,
          role: roleFromToken,
          avatarUrl: avatarUrlFromToken,
          phone: phoneFromToken,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        throw const ServerException(message: 'Authentication failed');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? e.message ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  @override
  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return data['access_token'] as String;
      } else {
        throw const ServerException(message: 'Failed to refresh token');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? e.message ?? 'Server error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
