import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/lead_repository.dart';

class ExportLeadsParams {
  final int? ownerId;
  final String? source;
  final String? status;
  final String? search;
  const ExportLeadsParams({
    this.ownerId,
    this.source,
    this.status,
    this.search,
  });
}

class ExportLeadsUseCase {
  final LeadRepository repository;
  ExportLeadsUseCase(this.repository);

  Future<Either<Failure, Uint8List>> call(ExportLeadsParams params) {
    return repository.exportLeads(
      ownerId: params.ownerId,
      source: params.source,
      status: params.status,
      search: params.search,
    );
  }
}
