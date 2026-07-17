import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/repositories/checklist_repository.dart';

class ChecklistRepositoryImpl implements ChecklistRepository {
  final ChecklistRemoteDataSource remoteDataSource;

  ChecklistRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ChecklistStage>>> getChecklistForDeal(String dealId) async {
    try {
      final stages = await remoteDataSource.getChecklistForDeal(dealId);
      return Right(stages);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChecklistStage>>> getChecklistForAccount(String accountId) async {
    try {
      final stages = await remoteDataSource.getChecklistForAccount(accountId);
      return Right(stages);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChecklistItem>> toggleItemStatus(String itemId, bool isCompleted) async {
    try {
      final item = await remoteDataSource.toggleItemStatus(itemId, isCompleted);
      return Right(item);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChecklistItem>> updateItemNotes(String itemId, String notes) async {
    try {
      final item = await remoteDataSource.updateItemNotes(itemId, notes);
      return Right(item);
    } on Exception catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
