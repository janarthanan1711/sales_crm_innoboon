import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/lead_repository.dart';

class DownloadImportTemplateUseCase {
  final LeadRepository repository;

  DownloadImportTemplateUseCase(this.repository);

  /// [format] is `'xlsx'` (default) or `'csv'`.
  Future<Either<Failure, Uint8List>> call({String format = 'xlsx'}) {
    return repository.downloadImportTemplate(format: format);
  }
}
