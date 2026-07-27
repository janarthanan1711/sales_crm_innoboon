import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal_stage_history.dart';
import '../repositories/deal_repository.dart';

class GetDealStageHistoryUseCase {
  final DealRepository repository;
  GetDealStageHistoryUseCase(this.repository);

  Future<Either<Failure, List<DealStageHistoryEntry>>> call(String dealId) =>
      repository.getStageHistory(dealId);
}
