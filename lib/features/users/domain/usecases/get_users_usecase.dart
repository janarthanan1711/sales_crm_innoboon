import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';
import '../repositories/user_repository.dart';

/// Fetches all users — used by owner-assignment dropdowns across
/// leads, deals, and accounts.
class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, List<OwnerUser>>> call() {
    return repository.getUsers();
  }
}
