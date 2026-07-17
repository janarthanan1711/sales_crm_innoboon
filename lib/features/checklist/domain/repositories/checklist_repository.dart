import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/checklist_item.dart';

abstract class ChecklistRepository {
  Future<Either<Failure, List<ChecklistStage>>> getChecklistForDeal(String dealId);
  Future<Either<Failure, List<ChecklistStage>>> getChecklistForAccount(String accountId);
  Future<Either<Failure, ChecklistItem>> toggleItemStatus(String itemId, bool isCompleted);
  Future<Either<Failure, ChecklistItem>> updateItemNotes(String itemId, String notes);
}

abstract class ChecklistRemoteDataSource {
  Future<List<ChecklistStage>> getChecklistForDeal(String dealId);
  Future<List<ChecklistStage>> getChecklistForAccount(String accountId);
  Future<ChecklistItem> toggleItemStatus(String itemId, bool isCompleted);
  Future<ChecklistItem> updateItemNotes(String itemId, String notes);
}
