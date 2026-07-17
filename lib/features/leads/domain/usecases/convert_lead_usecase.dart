import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lead_repository.dart';

class ConvertLeadToAccountUseCase implements UseCase<String, String> {
  final LeadRepository repository;
  ConvertLeadToAccountUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(String leadId) {
    return repository.convertToAccount(leadId);
  }
}
