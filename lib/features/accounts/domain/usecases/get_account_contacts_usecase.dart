import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../repositories/account_repository.dart';

class GetAccountContactsUseCase {
  final AccountRepository repository;
  GetAccountContactsUseCase(this.repository);

  Future<Either<Failure, List<Contact>>> call(String accountId) =>
      repository.getAccountContacts(accountId);
}
