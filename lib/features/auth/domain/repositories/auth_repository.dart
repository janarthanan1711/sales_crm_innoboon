import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Auth repository interface — domain layer.
abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  /// Cache-only — used for the app-boot session check. Does not hit the
  /// network; see [fetchCurrentUser] for a fresh `GET /users/me` call.
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, String>> refreshToken();

  /// Network `GET /users/me` — for the Profile page, which wants fresh
  /// data rather than the boot-time cache.
  Future<Either<Failure, User>> fetchCurrentUser();
  Future<Either<Failure, User>> updateCurrentUser({
    String? firstName,
    String? lastName,
    String? phoneNumber,
  });
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Either<Failure, User>> uploadAvatar({
    required Uint8List bytes,
    required String filename,
  });

  /// `DELETE /users/me/avatar` — removes the uploaded avatar and returns the
  /// updated user with `avatarUrl` cleared. Succeeds even if none was set.
  Future<Either<Failure, User>> deleteAvatar();

  /// Always succeeds server-side whether or not [email] is registered, to
  /// avoid leaking which emails have accounts.
  Future<Either<Failure, void>> forgotPassword(String email);

  /// Fails with [ServerFailure] ("Invalid or expired reset token") when
  /// [token] is unknown, already used, or past its expiry.
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });
}
