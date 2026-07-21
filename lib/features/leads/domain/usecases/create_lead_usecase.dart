import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import 'lead_upsert_params.dart';

class CreateLeadUseCase implements UseCase<Lead, LeadUpsertParams> {
  final LeadRepository repository;
  CreateLeadUseCase(this.repository);

  @override
  Future<Either<Failure, Lead>> call(LeadUpsertParams params) {
    return repository.createLead(params);
  }
}
