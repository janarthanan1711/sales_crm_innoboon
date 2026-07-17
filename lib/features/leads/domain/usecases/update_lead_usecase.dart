import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';
import 'lead_upsert_params.dart';

class UpdateLeadParams {
  final int id;
  final LeadUpsertParams data;
  const UpdateLeadParams({required this.id, required this.data});
}

class UpdateLeadUseCase implements UseCase<Lead, UpdateLeadParams> {
  final LeadRepository repository;
  UpdateLeadUseCase(this.repository);

  @override
  Future<Either<Failure, Lead>> call(UpdateLeadParams params) {
    return repository.updateLead(params.id, params.data);
  }
}
