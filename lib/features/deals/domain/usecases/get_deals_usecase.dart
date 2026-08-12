import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/deal.dart';
import '../repositories/deal_repository.dart';

class GetDealsParams {
  final int? ownerId;
  final String? accountId;
  final List<int>? stageId;
  final String? search;

  /// `created_at` (default) or `closed_at` — which timestamp `dateFrom`/
  /// `dateTo` filter against (API doc §6.3).
  final String? dateField;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// `all` (default), `open`, or `closed` — matches the dashboard's Deals in
  /// Pipeline (`open`) / Deals Closed (`closed`) tile semantics.
  final String? stageState;

  const GetDealsParams({
    this.ownerId,
    this.accountId,
    this.stageId,
    this.search,
    this.dateField,
    this.dateFrom,
    this.dateTo,
    this.stageState,
  });
}

class GetDealsUseCase implements UseCase<List<Deal>, GetDealsParams> {
  final DealRepository repository;
  GetDealsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Deal>>> call(GetDealsParams params) =>
      repository.getDeals(
        ownerId: params.ownerId,
        accountId: params.accountId,
        stageId: params.stageId,
        search: params.search,
        dateField: params.dateField,
        dateFrom: params.dateFrom,
        dateTo: params.dateTo,
        stageState: params.stageState,
      );
}
