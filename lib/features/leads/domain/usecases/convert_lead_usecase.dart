import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/lead_repository.dart';

class ConvertLeadParams {
  final int leadId;
  final String? tier;
  final int? ownerId;
  const ConvertLeadParams({required this.leadId, this.tier, this.ownerId});
}

/// Returns the newly created account's id.
class ConvertLeadToAccountUseCase implements UseCase<int, ConvertLeadParams> {
  final LeadRepository repository;
  ConvertLeadToAccountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(ConvertLeadParams params) {
    return repository.convertToAccount(
      params.leadId,
      tier: params.tier,
      ownerId: params.ownerId,
    );
  }
}
