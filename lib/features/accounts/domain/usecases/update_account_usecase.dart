import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';
import 'create_account_usecase.dart';

class UpdateAccountParams {
  final String id;
  final AccountUpsertParams data;
  const UpdateAccountParams({required this.id, required this.data});
}

class UpdateAccountUseCase {
  final AccountRepository repository;
  UpdateAccountUseCase(this.repository);

  Future<Either<Failure, Account>> call(UpdateAccountParams params) {
    return repository.updateAccount(
      params.id,
      company: params.data.company,
      domain: params.data.domain,
      tier: params.data.tier,
      ownerId: params.data.ownerId,
      industry: params.data.industry,
      city: params.data.city,
      description: params.data.description,
      linkedinUrl: params.data.linkedinUrl,
    );
  }
}
