import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches bearer token to outgoing requests.
/// Handles 401 → refresh-token → retry original request once.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _onRefreshToken;

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    Future<String?> Function()? onRefreshToken,
  }) : _secureStorage = secureStorage,
       _onRefreshToken = onRefreshToken;

  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login/refresh endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _onRefreshToken != null) {
      try {
        final newToken = await _onRefreshToken();
        if (newToken != null) {
          await _secureStorage.write(key: _tokenKey, value: newToken);

          // Retry the original request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(retryOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }
    }
    handler.next(err);
  }

  /// Save tokens after login
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _tokenKey);
  }
}
