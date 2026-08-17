import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/user_repository.dart';

/// Deactivates a user (default) or, with `permanent: true`, removes them
/// from the roster entirely — matches the Admin Settings Users tab's row
/// "Deactivate" and "Delete" actions respectively.
class DeleteUserUseCase {
  final UserRepository repository;
  DeleteUserUseCase(this.repository);

  Future<Either<Failure, void>> call(int id, {bool permanent = false}) =>
      repository.deleteUser(id, permanent: permanent);
}
