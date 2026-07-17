import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base use case interface.
/// Every use case has a single [call] method that takes [Params]
/// and returns [Either<Failure, Type>].
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use when the use case doesn't require any parameters
class NoParams {
  const NoParams();
}
