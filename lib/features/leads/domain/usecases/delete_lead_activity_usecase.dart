import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/lead_repository.dart';

class DeleteLeadActivityParams {
  final int leadId;
  final int activityId;

  const DeleteLeadActivityParams({
    required this.leadId,
    required this.activityId,
  });
}

class DeleteLeadActivityUseCase {
  final LeadRepository repository;

  DeleteLeadActivityUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteLeadActivityParams params) {
    return repository.deleteActivity(params.leadId, params.activityId);
  }
}
