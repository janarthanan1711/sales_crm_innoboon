import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';
import '../repositories/user_repository.dart';

/// Regenerates a user's password and resends the credentials email —
/// matches the Admin Settings Users tab's row "Re-invite" action. Also
/// reactivates the user if they were deactivated.
class ReinviteUserUseCase {
  final UserRepository repository;
  ReinviteUserUseCase(this.repository);

  Future<Either<Failure, OwnerUser>> call(int id) => repository.reinviteUser(id);
}
