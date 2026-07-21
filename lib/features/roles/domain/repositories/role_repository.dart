import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/permission.dart';
import '../entities/role.dart';

abstract class RoleRepository {
  Future<Either<Failure, List<Permission>>> getPermissions();
  Future<Either<Failure, List<Role>>> getRoles();
  Future<Either<Failure, Role>> createRole({
    required String name,
    String? description,
    required List<int> permissionIds,
  });
  Future<Either<Failure, Role>> updateRole(
    int id, {
    String? name,
    String? description,
    List<int>? permissionIds,
  });
  Future<Either<Failure, void>> deleteRole(int id);
}

abstract class RoleRemoteDataSource {
  Future<List<Permission>> getPermissions();
  Future<List<Role>> getRoles();
  Future<Role> createRole({
    required String name,
    String? description,
    required List<int> permissionIds,
  });
  Future<Role> updateRole(
    int id, {
    String? name,
    String? description,
    List<int>? permissionIds,
  });
  Future<void> deleteRole(int id);
}
