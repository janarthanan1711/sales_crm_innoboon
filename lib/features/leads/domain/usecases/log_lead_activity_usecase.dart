import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class LogLeadActivityParams {
  final int leadId;
  final String type;
  final String note;

  const LogLeadActivityParams({
    required this.leadId,
    required this.type,
    required this.note,
  });
}

class LogLeadActivityUseCase {
  final LeadRepository repository;

  LogLeadActivityUseCase(this.repository);

  Future<Either<Failure, LeadActivity>> call(LogLeadActivityParams params) {
    return repository.logActivity(
      params.leadId,
      type: params.type,
      note: params.note,
    );
  }
}
