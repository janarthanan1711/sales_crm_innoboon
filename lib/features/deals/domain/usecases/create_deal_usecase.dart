import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class CreateDealParams {
  final String dealName;
  final String accountId;
  final double value;
  final String currency;
  final DateTime? expectedCloseDate;
  final DealStage stage;
  final int? ownerId;

  const CreateDealParams({
    required this.dealName,
    required this.accountId,
    required this.value,
    this.currency = 'INR',
    this.expectedCloseDate,
    required this.stage,
    this.ownerId,
  });
}

class CreateDealUseCase {
  final DealRepository repository;
  CreateDealUseCase(this.repository);

  Future<Either<Failure, Deal>> call(CreateDealParams params) {
    return repository.createDeal(
      dealName: params.dealName,
      accountId: params.accountId,
      value: params.value,
      currency: params.currency,
      expectedCloseDate: params.expectedCloseDate,
      stage: params.stage,
      ownerId: params.ownerId,
    );
  }
}
