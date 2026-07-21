import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealStageParams {
  final String id;
  final DealStage stage;
  final String? note;
  const UpdateDealStageParams({
    required this.id,
    required this.stage,
    this.note,
  });
}

/// Stage changes go through the same `PATCH /deals/{id}` as any other
/// update — [UpdateDealStageParams.note] is written to the resulting
/// stage-history row (see `GET /deals/{id}/stage-history`).
class UpdateDealStageUseCase implements UseCase<Deal, UpdateDealStageParams> {
  final DealRepository repository;
  UpdateDealStageUseCase(this.repository);

  @override
  Future<Either<Failure, Deal>> call(UpdateDealStageParams params) =>
      repository.updateDeal(params.id, stage: params.stage, note: params.note);
}
