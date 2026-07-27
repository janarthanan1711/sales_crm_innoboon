import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';
import '../repositories/user_repository.dart';

class CreateUserParams {
  final String email;
  final String firstName;
  final String lastName;
  final int roleId;
  const CreateUserParams({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roleId,
  });
}

/// Creates a user — the backend auto-generates a password and emails
/// credentials (see doc §2.1), matching the Admin Settings "+ Invite User"
/// action.
class CreateUserUseCase {
  final UserRepository repository;
  CreateUserUseCase(this.repository);

  Future<Either<Failure, OwnerUser>> call(CreateUserParams params) {
    return repository.createUser(
      email: params.email,
      firstName: params.firstName,
      lastName: params.lastName,
      roleId: params.roleId,
    );
  }
}
