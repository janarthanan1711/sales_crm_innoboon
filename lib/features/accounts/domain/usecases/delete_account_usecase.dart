import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/account_repository.dart';

class DeleteAccountUseCase implements UseCase<Unit, String> {
  final AccountRepository repository;
  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => repository.deleteAccount(id);
}
