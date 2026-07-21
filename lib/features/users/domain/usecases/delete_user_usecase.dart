import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

/// Soft-deletes (deactivates) a user — matches the Admin Settings Users
/// tab's row "Deactivate" action.
class DeleteUserUseCase {
  final UserRepository repository;
  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.deleteUser(id);
}
