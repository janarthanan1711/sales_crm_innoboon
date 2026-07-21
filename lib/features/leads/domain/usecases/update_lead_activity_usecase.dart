import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class UpdateLeadActivityParams {
  final int leadId;
  final int activityId;
  final String? type;
  final String? note;

  const UpdateLeadActivityParams({
    required this.leadId,
    required this.activityId,
    this.type,
    this.note,
  });
}

class UpdateLeadActivityUseCase {
  final LeadRepository repository;

  UpdateLeadActivityUseCase(this.repository);

  Future<Either<Failure, LeadActivity>> call(
    UpdateLeadActivityParams params,
  ) {
    return repository.updateActivity(
      params.leadId,
      params.activityId,
      type: params.type,
      note: params.note,
    );
  }
}
