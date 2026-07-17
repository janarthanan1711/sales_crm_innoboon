import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches bearer token to outgoing requests.
/// Backend has no refresh-token endpoint — a 401 just propagates and the
/// caller sends the user back to login.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  static const String _tokenKey = 'access_token';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for the login endpoint
    if (options.path.contains('/auth/login')) {
      return handler.next(options);
    }

    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Save access token after login
  Future<void> saveTokens({required String accessToken}) async {
    await _secureStorage.write(key: _tokenKey, value: accessToken);
  }

  /// Clear token on logout
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _tokenKey);
  }
}
