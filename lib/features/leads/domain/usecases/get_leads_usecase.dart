import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class GetLeadsParams {
  final int? ownerId;
  final String? source;
  final String? status;
  final String? search;
  final int limit;
  final int offset;

  const GetLeadsParams({
    this.ownerId,
    this.source,
    this.status,
    this.search,
    this.limit = 20,
    this.offset = 0,
  });
}

class GetLeadsUseCase
    implements UseCase<({List<Lead> items, int total}), GetLeadsParams> {
  final LeadRepository repository;
  GetLeadsUseCase(this.repository);

  @override
  Future<Either<Failure, ({List<Lead> items, int total})>> call(
    GetLeadsParams params,
  ) {
    return repository.getLeads(
      ownerId: params.ownerId,
      source: params.source,
      status: params.status,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
