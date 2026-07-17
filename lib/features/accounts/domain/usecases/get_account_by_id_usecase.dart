import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetAccountByIdUseCase implements UseCase<Account, String> {
  final AccountRepository repository;
  GetAccountByIdUseCase(this.repository);
  @override
  Future<Either<Failure, Account>> call(String id) => repository.getAccountById(id);
}
