import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/account_repository.dart';

class ExportAccountsParams {
  final String? search;
  final String? industry;
  final String? tier;
  final int? ownerId;
  const ExportAccountsParams({
    this.search,
    this.industry,
    this.tier,
    this.ownerId,
  });
}

class ExportAccountsUseCase {
  final AccountRepository repository;
  ExportAccountsUseCase(this.repository);

  Future<Either<Failure, Uint8List>> call(ExportAccountsParams params) {
    return repository.exportAccounts(
      search: params.search,
      industry: params.industry,
      tier: params.tier,
      ownerId: params.ownerId,
    );
  }
}
