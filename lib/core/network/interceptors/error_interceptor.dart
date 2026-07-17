import 'package:dio/dio.dart';
import '../../error/exceptions.dart';

/// Normalizes [DioException] types into consistent internal exceptions.
/// This runs before the error reaches the repository layer.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const TimeoutException(),
            type: err.type,
            response: err.response,
          ),
        );
        return;

      case DioExceptionType.connectionError:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(),
            type: err.type,
            response: err.response,
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        final message = _extractErrorMessage(responseData) ??
            'Server error occurred';

        if (statusCode == 401) {
          handler.next(
            DioException(
              requestOptions: err.requestOptions,
              error: const AuthException(),
              type: err.type,
              response: err.response,
            ),
          );
          return;
        }

        if (statusCode == 404) {
          handler.next(
            DioException(
              requestOptions: err.requestOptions,
              error: const NotFoundException(),
              type: err.type,
              response: err.response,
            ),
          );
          return;
        }

        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(
              message: message,
              statusCode: statusCode,
            ),
            type: err.type,
            response: err.response,
          ),
        );
        return;

      default:
        handler.next(err);
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    if (data is String) return data;
    return null;
  }
}
