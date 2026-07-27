import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead.dart';
import '../repositories/lead_repository.dart';

class ListLeadActivitiesParams {
  final int leadId;
  final List<String>? types;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ListLeadActivitiesParams({
    required this.leadId,
    this.types,
    this.dateFrom,
    this.dateTo,
  });
}

class ListLeadActivitiesUseCase {
  final LeadRepository repository;

  ListLeadActivitiesUseCase(this.repository);

  Future<Either<Failure, List<LeadActivity>>> call(
    ListLeadActivitiesParams params,
  ) {
    return repository.listActivities(
      params.leadId,
      types: params.types,
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
    );
  }
}
