import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class SetLeadFavouriteParams {
  final int id;
  final bool isFavourite;
  const SetLeadFavouriteParams({required this.id, required this.isFavourite});
}

class SetLeadFavouriteUseCase {
  final LeadRepository repository;
  SetLeadFavouriteUseCase(this.repository);
  Future<Either<Failure, Lead>> call(SetLeadFavouriteParams params) {
    return repository.setFavourite(params.id, params.isFavourite);
  }
}
