import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class GetDealByIdUseCase implements UseCase<Deal, String> {
  final DealRepository repository;
  GetDealByIdUseCase(this.repository);
  @override
  Future<Either<Failure, Deal>> call(String id) => repository.getDealById(id);
}
