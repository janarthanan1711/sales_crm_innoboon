import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class CreateLeadUseCase implements UseCase<Lead, Lead> {
  final LeadRepository repository;
  CreateLeadUseCase(this.repository);

  @override
  Future<Either<Failure, Lead>> call(Lead lead) {
    return repository.createLead(lead);
  }
}
