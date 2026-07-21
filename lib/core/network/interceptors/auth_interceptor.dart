import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Attaches bearer token to outgoing requests.
/// On a 401, exchanges the refresh token for a new access token and retries
/// the original request once (guarded against retry loops).
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _onRefreshToken;
  Dio? _dio;

  AuthInterceptor({
    required FlutterSecureStorage secureStorage,
    Future<String?> Function()? onRefreshToken,
  }) : _secureStorage = secureStorage,
       _onRefreshToken = onRefreshToken;

  static const String _tokenKey = 'access_token';
  static const String _retriedFlag = 'authRetried';

  /// Set by [DioClient] after building its Dio instance, so a retry goes
  /// through the same client (base URL + interceptor chain) instead of a
  /// bare `Dio()` that would skip both.
  void attachDio(Dio dio) => _dio = dio;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for endpoints that don't need (or must not require) it
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
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    if (err.response?.statusCode == 401 &&
        _onRefreshToken != null &&
        _dio != null &&
        !alreadyRetried) {
      try {
        final newToken = await _onRefreshToken();
        if (newToken != null) {
          await _secureStorage.write(key: _tokenKey, value: newToken);

          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          retryOptions.extra[_retriedFlag] = true;
          final response = await _dio!.fetch(retryOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }
    }
    handler.next(err);
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
