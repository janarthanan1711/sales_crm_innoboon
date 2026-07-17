import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class GetLeadsParams {
  final String? search;
  final String? status;
  final String? tier;
  final String? owner;
  final String? source;
  final int page;
  final int pageSize;

  const GetLeadsParams({
    this.search,
    this.status,
    this.tier,
    this.owner,
    this.source,
    this.page = 1,
    this.pageSize = 25,
  });
}

class GetLeadsUseCase implements UseCase<List<Lead>, GetLeadsParams> {
  final LeadRepository repository;
  GetLeadsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Lead>>> call(GetLeadsParams params) {
    return repository.getLeads(
      search: params.search,
      status: params.status,
      tier: params.tier,
      owner: params.owner,
      source: params.source,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}
