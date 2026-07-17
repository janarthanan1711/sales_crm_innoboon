import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/owner_user.dart';

/// Repository interface for the users feature.
abstract class UserRepository {
  Future<Either<Failure, List<OwnerUser>>> getUsers();
}
