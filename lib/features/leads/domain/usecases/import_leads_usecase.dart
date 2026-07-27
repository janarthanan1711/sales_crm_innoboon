import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/lead_import_result.dart';
import '../repositories/lead_repository.dart';

class ImportLeadsParams {
  final Uint8List bytes;
  final String filename;

  const ImportLeadsParams({required this.bytes, required this.filename});
}

class ImportLeadsUseCase {
  final LeadRepository repository;

  ImportLeadsUseCase(this.repository);

  Future<Either<Failure, LeadImportResult>> call(ImportLeadsParams params) {
    return repository.importLeads(
      bytes: params.bytes,
      filename: params.filename,
    );
  }
}
