import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Singleton Dio client with all interceptors configured.
/// All remote datasources inject this — never create `Dio()` inline.
class DioClient {
  late final Dio _dio;

  DioClient({
    required String baseUrl,
    required AuthInterceptor authInterceptor,
    bool enableLogging = true,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // ngrok free tier serves an HTML interstitial to browser-like
          // clients unless this header is present; it also lets ngrok pass
          // the request straight through instead of interfering.
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // Order matters: auth first, then error normalization, then logging
    _dio.interceptors.add(authInterceptor);
    _dio.interceptors.add(ErrorInterceptor());
    if (enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    // So a 401 retry goes through this same client, not a bare Dio().
    authInterceptor.attachDio(_dio);
  }

  Dio get dio => _dio;

  /// On Flutter Web the XMLHttpRequest adapter throws when [sendTimeout]
  /// is set on a request that carries no body (GET, DELETE, HEAD).
  /// Merging `sendTimeout: null` into [options] prevents this.
  Options _webSafe(Options? options) {
    if (!kIsWeb) return options ?? Options();
    final merged = options ?? Options();
    merged.sendTimeout = null;
    return merged;
  }

  // ─── Convenience HTTP methods ──────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: _webSafe(options),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: _webSafe(options),
    );
  }
}
