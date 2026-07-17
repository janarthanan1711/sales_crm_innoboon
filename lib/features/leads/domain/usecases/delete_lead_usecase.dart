import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lead_repository.dart';

class DeleteLeadUseCase implements UseCase<void, int> {
  final LeadRepository repository;
  DeleteLeadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int id) {
    return repository.deleteLead(id);
  }
}
