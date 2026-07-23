import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class UpdateDealParams {
  final String id;
  final String? dealName;
  final double? value;
  final String? currency;
  final DateTime? expectedCloseDate;
  final int? stageId;
  final List<int>? contactIds;
  final String? coldReason;
  final int? ownerId;
  final String? note;

  const UpdateDealParams({
    required this.id,
    this.dealName,
    this.value,
    this.currency,
    this.expectedCloseDate,
    this.stageId,
    this.contactIds,
    this.coldReason,
    this.ownerId,
    this.note,
  });
}

class UpdateDealUseCase {
  final DealRepository repository;
  UpdateDealUseCase(this.repository);

  Future<Either<Failure, Deal>> call(UpdateDealParams params) {
    return repository.updateDeal(
      params.id,
      dealName: params.dealName,
      value: params.value,
      currency: params.currency,
      expectedCloseDate: params.expectedCloseDate,
      stageId: params.stageId,
      contactIds: params.contactIds,
      coldReason: params.coldReason,
      ownerId: params.ownerId,
      note: params.note,
    );
  }
}
