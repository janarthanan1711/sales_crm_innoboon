import 'package:equatable/equatable.dart';

/// Base failure class for error handling across the app.
/// All specific failures extend this class.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server-side error (API returned non-2xx)
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
  });
}

/// Local cache/storage error
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
  });
}

/// Network connectivity error (no internet)
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection. Please check your network.',
  });
}

/// Authentication error (unauthorized, token expired)
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed. Please log in again.',
    super.statusCode = 401,
  });
}

/// Validation error (invalid input from user)
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Permission/authorization error
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
  });
}

/// Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
  });
}

/// Timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
  });
}

/// Unknown / unexpected error
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
  });
}
