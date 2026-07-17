import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/checklist_item.dart';
import '../repositories/checklist_repository.dart';

class GetChecklistForDealUseCase implements UseCase<List<ChecklistStage>, String> {
  final ChecklistRepository repository;
  GetChecklistForDealUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<ChecklistStage>>> call(String dealId) => 
      repository.getChecklistForDeal(dealId);
}

class ToggleChecklistItemParams {
  final String itemId;
  final bool isCompleted;
  const ToggleChecklistItemParams({required this.itemId, required this.isCompleted});
}

class ToggleChecklistItemUseCase implements UseCase<ChecklistItem, ToggleChecklistItemParams> {
  final ChecklistRepository repository;
  ToggleChecklistItemUseCase(this.repository);
  
  @override
  Future<Either<Failure, ChecklistItem>> call(ToggleChecklistItemParams params) => 
      repository.toggleItemStatus(params.itemId, params.isCompleted);
}
