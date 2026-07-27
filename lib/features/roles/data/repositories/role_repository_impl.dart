import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/role_repository.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDataSource remoteDataSource;

  RoleRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Permission>>> getPermissions() async {
    try {
      return Right(await remoteDataSource.getPermissions());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Role>>> getRoles() async {
    try {
      return Right(await remoteDataSource.getRoles());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Role>> createRole({
    required String name,
    String? description,
    required List<int> permissionIds,
  }) async {
    try {
      final role = await remoteDataSource.createRole(
        name: name,
        description: description,
        permissionIds: permissionIds,
      );
      return Right(role);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Role>> updateRole(
    int id, {
    String? name,
    String? description,
    List<int>? permissionIds,
  }) async {
    try {
      final role = await remoteDataSource.updateRole(
        id,
        name: name,
        description: description,
        permissionIds: permissionIds,
      );
      return Right(role);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRole(int id) async {
    try {
      await remoteDataSource.deleteRole(id);
      return const Right(null);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
