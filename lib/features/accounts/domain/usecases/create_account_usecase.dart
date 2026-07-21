import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/account.dart';
import '../repositories/account_repository.dart';

class AccountUpsertParams {
  final String company;
  final String? domain;
  final String tier;
  final int? ownerId;
  final String? industry;
  final String? city;
  final String? description;
  final String? linkedinUrl;

  const AccountUpsertParams({
    required this.company,
    this.domain,
    required this.tier,
    this.ownerId,
    this.industry,
    this.city,
    this.description,
    this.linkedinUrl,
  });
}

class CreateAccountUseCase {
  final AccountRepository repository;
  CreateAccountUseCase(this.repository);

  Future<Either<Failure, Account>> call(AccountUpsertParams params) {
    return repository.createAccount(
      company: params.company,
      domain: params.domain,
      tier: params.tier,
      ownerId: params.ownerId,
      industry: params.industry,
      city: params.city,
      description: params.description,
      linkedinUrl: params.linkedinUrl,
    );
  }
}
