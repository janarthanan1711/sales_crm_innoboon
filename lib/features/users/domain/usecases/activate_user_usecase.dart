import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

/// Reactivates a deactivated user — matches the Admin Settings Users
/// tab's row "Activate" action.
class ActivateUserUseCase {
  final UserRepository repository;
  ActivateUserUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.activateUser(id);
}
