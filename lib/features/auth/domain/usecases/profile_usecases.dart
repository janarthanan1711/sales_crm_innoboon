import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Network `GET /users/me` — for the Profile page (fresh data, unlike the
/// cache-only [GetCurrentUserUseCase] used at app boot).
class FetchCurrentUserUseCase {
  final AuthRepository repository;
  FetchCurrentUserUseCase(this.repository);
  Future<Either<Failure, User>> call() => repository.fetchCurrentUser();
}

class UpdateCurrentUserParams {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  const UpdateCurrentUserParams({this.firstName, this.lastName, this.phoneNumber});
}

class UpdateCurrentUserUseCase {
  final AuthRepository repository;
  UpdateCurrentUserUseCase(this.repository);
  Future<Either<Failure, User>> call(UpdateCurrentUserParams params) {
    return repository.updateCurrentUser(
      firstName: params.firstName,
      lastName: params.lastName,
      phoneNumber: params.phoneNumber,
    );
  }
}

class ChangePasswordParams {
  final String currentPassword;
  final String newPassword;
  const ChangePasswordParams({required this.currentPassword, required this.newPassword});
}

class ChangePasswordUseCase {
  final AuthRepository repository;
  ChangePasswordUseCase(this.repository);
  Future<Either<Failure, void>> call(ChangePasswordParams params) {
    return repository.changePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class UploadAvatarParams {
  final Uint8List bytes;
  final String filename;
  const UploadAvatarParams({required this.bytes, required this.filename});
}

class UploadAvatarUseCase {
  final AuthRepository repository;
  UploadAvatarUseCase(this.repository);
  Future<Either<Failure, User>> call(UploadAvatarParams params) {
    return repository.uploadAvatar(bytes: params.bytes, filename: params.filename);
  }
}
