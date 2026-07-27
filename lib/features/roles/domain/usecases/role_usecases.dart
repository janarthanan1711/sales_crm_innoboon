import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/permission.dart';
import '../entities/role.dart';
import '../repositories/role_repository.dart';

class ListPermissionsUseCase {
  final RoleRepository repository;
  ListPermissionsUseCase(this.repository);
  Future<Either<Failure, List<Permission>>> call() => repository.getPermissions();
}

class ListRolesUseCase {
  final RoleRepository repository;
  ListRolesUseCase(this.repository);
  Future<Either<Failure, List<Role>>> call() => repository.getRoles();
}

class CreateRoleParams {
  final String name;
  final String? description;
  final List<int> permissionIds;
  const CreateRoleParams({
    required this.name,
    this.description,
    required this.permissionIds,
  });
}

class CreateRoleUseCase {
  final RoleRepository repository;
  CreateRoleUseCase(this.repository);
  Future<Either<Failure, Role>> call(CreateRoleParams params) {
    return repository.createRole(
      name: params.name,
      description: params.description,
      permissionIds: params.permissionIds,
    );
  }
}

class UpdateRoleParams {
  final int id;
  final String? name;
  final String? description;
  final List<int>? permissionIds;
  const UpdateRoleParams({
    required this.id,
    this.name,
    this.description,
    this.permissionIds,
  });
}

class UpdateRoleUseCase {
  final RoleRepository repository;
  UpdateRoleUseCase(this.repository);
  Future<Either<Failure, Role>> call(UpdateRoleParams params) {
    return repository.updateRole(
      params.id,
      name: params.name,
      description: params.description,
      permissionIds: params.permissionIds,
    );
  }
}

class DeleteRoleUseCase {
  final RoleRepository repository;
  DeleteRoleUseCase(this.repository);
  Future<Either<Failure, void>> call(int id) => repository.deleteRole(id);
}
