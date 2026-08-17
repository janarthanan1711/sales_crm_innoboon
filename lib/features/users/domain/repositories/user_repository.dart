import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';

/// Repository interface for the users feature.
abstract class UserRepository {
  Future<Either<Failure, List<OwnerUser>>> getUsers({
    int? roleId,
    bool? isActive,
    String? status,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<Either<Failure, OwnerUser>> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required int roleId,
  });
  Future<Either<Failure, void>> deleteUser(int id, {bool permanent = false});
  Future<Either<Failure, void>> activateUser(int id);
  Future<Either<Failure, OwnerUser>> reinviteUser(int id);
  Future<Either<Failure, OwnerUser>> updateUserRole(int id, int roleId);
}
