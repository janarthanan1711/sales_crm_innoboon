import '../../../accounts/domain/entities/source_person.dart';
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
  final String? tier;
  final int? ownerId;
  final String? note;

  /// Empty map clears the scoring; null leaves it untouched.
  final Map<String, String>? scores;
  final DateTime? followUpDate;
  final bool clearFollowUp;
  final SourcePerson? originator;
  final bool clearOriginator;
  final String? proposalStatus;
  final DateTime? proposalSentAt;

  const UpdateDealParams({
    required this.id,
    this.dealName,
    this.value,
    this.currency,
    this.expectedCloseDate,
    this.stageId,
    this.contactIds,
    this.tier,
    this.coldReason,
    this.ownerId,
    this.note,
    this.scores,
    this.followUpDate,
    this.clearFollowUp = false,
    this.originator,
    this.clearOriginator = false,
    this.proposalStatus,
    this.proposalSentAt,
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
      tier: params.tier,
      ownerId: params.ownerId,
      note: params.note,
      scores: params.scores,
      followUpDate: params.followUpDate,
      clearFollowUp: params.clearFollowUp,
      originator: params.originator,
      clearOriginator: params.clearOriginator,
      proposalStatus: params.proposalStatus,
      proposalSentAt: params.proposalSentAt,
    );
  }
}
