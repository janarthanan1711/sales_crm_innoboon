import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealStageParams {
  final String id;
  final DealStage stage;
  const UpdateDealStageParams({required this.id, required this.stage});
}

class UpdateDealStageUseCase implements UseCase<Deal, UpdateDealStageParams> {
  final DealRepository repository;
  UpdateDealStageUseCase(this.repository);
  
  @override
  Future<Either<Failure, Deal>> call(UpdateDealStageParams params) => 
      repository.updateDealStage(params.id, params.stage);
}
