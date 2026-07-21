import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/contact.dart';
import '../repositories/contact_repository.dart';

class CreateContactParams {
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final int accountId;

  const CreateContactParams({
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
    required this.accountId,
  });
}

class CreateContactUseCase {
  final ContactRepository repository;
  CreateContactUseCase(this.repository);

  Future<Either<Failure, Contact>> call(CreateContactParams params) {
    return repository.createContact(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      phone: params.phone,
      jobTitle: params.jobTitle,
      accountId: params.accountId,
    );
  }
}

class UpdateContactParams {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobTitle;

  const UpdateContactParams({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
  });
}

class UpdateContactUseCase {
  final ContactRepository repository;
  UpdateContactUseCase(this.repository);

  Future<Either<Failure, Contact>> call(UpdateContactParams params) {
    return repository.updateContact(
      params.id,
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      phone: params.phone,
      jobTitle: params.jobTitle,
    );
  }
}

class DeleteContactUseCase {
  final ContactRepository repository;
  DeleteContactUseCase(this.repository);

  Future<Either<Failure, void>> call(int id) => repository.deleteContact(id);
}
