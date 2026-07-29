/// Base exception for API/server errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

/// Exception for local cache/storage operations
class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache operation failed'});

  @override
  String toString() => 'CacheException: $message';
}

/// Exception for network connectivity issues
class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for authentication failures (401)
class AuthException implements Exception {
  final String message;

  const AuthException({this.message = 'Authentication failed'});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception for timeout errors
class TimeoutException implements Exception {
  final String message;

  const TimeoutException({this.message = 'Request timed out'});

  @override
  String toString() => 'TimeoutException: $message';
}

/// Exception for not found (404)
class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'Resource not found'});

  @override
  String toString() => 'NotFoundException: $message';
}
