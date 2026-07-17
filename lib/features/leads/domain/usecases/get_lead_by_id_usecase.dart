import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class GetLeadByIdUseCase implements UseCase<Lead, String> {
  final LeadRepository repository;
  GetLeadByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Lead>> call(String id) {
    return repository.getLeadById(id);
  }
}
