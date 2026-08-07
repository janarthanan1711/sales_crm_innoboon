import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// `POST /auth/forgot-password` — pre-login, no auth required.
class ForgotPasswordUseCase {
  final AuthRepository repository;
  ForgotPasswordUseCase(this.repository);
  Future<Either<Failure, void>> call(String email) => repository.forgotPassword(email);
}

class ResetPasswordParams {
  final String token;
  final String newPassword;
  const ResetPasswordParams({required this.token, required this.newPassword});
}

/// `POST /auth/reset-password` — pre-login, no auth required.
class ResetPasswordUseCase {
  final AuthRepository repository;
  ResetPasswordUseCase(this.repository);
  Future<Either<Failure, void>> call(ResetPasswordParams params) {
    return repository.resetPassword(token: params.token, newPassword: params.newPassword);
  }
}
