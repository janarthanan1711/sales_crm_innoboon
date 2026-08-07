import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/deal_repository.dart';

class ExportDealsParams {
  final int? ownerId;
  final int? stageId;

  /// Empty or null = no tier filter. `tier` is repeatable on the API, so the
  /// UI's multi-select tier checkboxes map straight through.
  final List<String>? tiers;
  final String? search;
  const ExportDealsParams({
    this.ownerId,
    this.stageId,
    this.tiers,
    this.search,
  });
}

class ExportDealsUseCase {
  final DealRepository repository;
  ExportDealsUseCase(this.repository);

  Future<Either<Failure, Uint8List>> call(ExportDealsParams params) {
    return repository.exportDeals(
      ownerId: params.ownerId,
      stageId: params.stageId,
      tiers: params.tiers,
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
