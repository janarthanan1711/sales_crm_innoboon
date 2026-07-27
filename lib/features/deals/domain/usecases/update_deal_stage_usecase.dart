import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealStageParams {
  final String id;
  final int stageId;
  final String? note;
  final String? coldReason;
  const UpdateDealStageParams({
    required this.id,
    required this.stageId,
    this.note,
    this.coldReason,
  });
}

/// Stage changes go through the same `PATCH /deals/{id}` as any other
/// update — [UpdateDealStageParams.note] is written to the resulting
/// stage-history row. [coldReason] is required when moving to a cold stage.
class UpdateDealStageUseCase implements UseCase<Deal, UpdateDealStageParams> {
  final DealRepository repository;
  UpdateDealStageUseCase(this.repository);

  @override
  Future<Either<Failure, Deal>> call(UpdateDealStageParams params) =>
      repository.updateDeal(
        params.id,
        stageId: params.stageId,
        note: params.note,
        coldReason: params.coldReason,
      );
}
