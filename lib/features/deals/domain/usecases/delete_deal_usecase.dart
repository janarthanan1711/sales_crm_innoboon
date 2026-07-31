import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/deal_repository.dart';

class DeleteDealUseCase implements UseCase<Unit, String> {
  final DealRepository repository;
  DeleteDealUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String id) => repository.deleteDeal(id);
}
