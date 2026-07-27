import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal_stage_def.dart';
import '../repositories/deal_repository.dart';

class GetDealStagesUseCase {
  final DealRepository repository;
  GetDealStagesUseCase(this.repository);

  Future<Either<Failure, List<DealStageDef>>> call() => repository.getDealStages();
}
