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
  final int stageId;
  final List<int>? contactIds;
  final String? tier;
  final String? coldReason;
  final int? ownerId;

  const CreateDealParams({
    required this.dealName,
    required this.accountId,
    required this.value,
    this.currency = 'INR',
    this.expectedCloseDate,
    required this.stageId,
    this.contactIds,
    this.tier,
    this.coldReason,
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
      stageId: params.stageId,
      contactIds: params.contactIds,
      tier: params.tier,
      coldReason: params.coldReason,
      ownerId: params.ownerId,
    );
  }
}
