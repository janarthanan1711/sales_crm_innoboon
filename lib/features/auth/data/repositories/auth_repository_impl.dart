import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final userModel = await remoteDataSource.login(email, password);

      await localDataSource.saveUser(userModel);
      if (userModel.accessToken != null) {
        await localDataSource.saveAccessToken(userModel.accessToken!);
      }
      if (userModel.refreshToken != null) {
        await localDataSource.saveRefreshToken(userModel.refreshToken!);
      }

      return Right(userModel.toEntity());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken != null) {
        // Best-effort: the user can still log out locally even if the
        // revoke call fails (offline, token already expired, etc).
        try {
          await remoteDataSource.logout(refreshToken);
        } on Exception {
          // ignore — local clear below still runs
        }
      }
      await localDataSource.clearAll();
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      return const Left(AuthFailure(message: 'No cached user found'));
    } on Exception catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final currentRefreshToken = await localDataSource.getRefreshToken();
      if (currentRefreshToken == null) {
        return const Left(AuthFailure(message: 'No refresh token'));
      }
      final newAccessToken = await remoteDataSource.refreshToken(currentRefreshToken);
      await localDataSource.saveAccessToken(newAccessToken);
      return Right(newAccessToken);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
