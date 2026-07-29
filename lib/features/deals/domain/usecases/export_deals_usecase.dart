import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/deal_repository.dart';

class ExportDealsParams {
  final int? stageId;
  final String? tier;
  final String? search;
  const ExportDealsParams({this.stageId, this.tier, this.search});
}

class ExportDealsUseCase {
  final DealRepository repository;
  ExportDealsUseCase(this.repository);

  Future<Either<Failure, Uint8List>> call(ExportDealsParams params) {
    return repository.exportDeals(
      stageId: params.stageId,
      tier: params.tier,
      search: params.search,
    );
  }
}

/// Single-deal export — `GET /deals/{id}?to_export=true`, an xlsx with the
/// deal's fields plus a sheet of its stage-transition history.
class ExportDealDetailUseCase {
  final DealRepository repository;
  ExportDealDetailUseCase(this.repository);

  Future<Either<Failure, Uint8List>> call(String id) =>
      repository.exportDeal(id);
}
