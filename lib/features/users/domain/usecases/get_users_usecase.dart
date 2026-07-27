import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';
import '../repositories/user_repository.dart';

/// Fetches users — used both by owner-assignment dropdowns across
/// leads/deals/accounts (no filters) and by the Admin Settings Users tab
/// (with filters).
class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<Either<Failure, List<OwnerUser>>> call({
    int? roleId,
    bool? isActive,
    String? status,
    String? search,
  }) {
    return repository.getUsers(
      roleId: roleId,
      isActive: isActive,
      status: status,
      search: search,
    );
  }
}
