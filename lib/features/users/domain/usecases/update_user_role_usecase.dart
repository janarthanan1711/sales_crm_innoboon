import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';
import '../repositories/user_repository.dart';

/// Changes an existing user's role — matches the Admin Settings Users
/// tab's row "Change Role" action.
class UpdateUserRoleUseCase {
  final UserRepository repository;
  UpdateUserRoleUseCase(this.repository);

  Future<Either<Failure, OwnerUser>> call(int id, int roleId) =>
      repository.updateUserRole(id, roleId);
}
