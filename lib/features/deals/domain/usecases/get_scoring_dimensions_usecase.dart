import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/scoring_dimension.dart';
import '../repositories/deal_repository.dart';

class GetScoringDimensionsUseCase {
  final DealRepository repository;
  GetScoringDimensionsUseCase(this.repository);

  Future<Either<Failure, List<ScoringDimension>>> call() =>
      repository.getScoringDimensions();
}
