import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class CreateDealUseCase implements UseCase<Deal, Deal> {
  final DealRepository repository;
  CreateDealUseCase(this.repository);
  @override
  Future<Either<Failure, Deal>> call(Deal deal) => repository.createDeal(deal);
}
