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

      // Cache user and tokens
      await localDataSource.saveUser(userModel);
      if (userModel.accessToken != null) {
        await localDataSource.saveTokens(
          userModel.accessToken!,
          userModel.refreshToken,
        );
      }

      return Right(userModel.toEntity());
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
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
      final newToken =
          await remoteDataSource.refreshToken(currentRefreshToken);
      await localDataSource.saveTokens(newToken, null);
      return Right(newToken);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
