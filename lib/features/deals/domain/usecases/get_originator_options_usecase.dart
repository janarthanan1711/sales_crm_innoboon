import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../accounts/domain/entities/source_person.dart';
import '../repositories/deal_repository.dart';

/// Users + contacts flagged `is_originator`, for the deal Originator dropdown.
class GetOriginatorOptionsUseCase {
  final DealRepository repository;
  GetOriginatorOptionsUseCase(this.repository);

  Future<Either<Failure, List<SourcePerson>>> call() =>
      repository.getOriginatorOptions();
}
