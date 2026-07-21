import 'package:equatable/equatable.dart';

/// A contact belonging to an account — mirrors the backend's `ContactRead`
/// shape exactly (see `POST/GET/PATCH/DELETE /contacts`).
class Contact extends Equatable {
  final int id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? jobTitle;
  final int accountId;

  const Contact({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.jobTitle,
    required this.accountId,
  });

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');

  Contact copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? jobTitle,
    int? accountId,
  }) {
    return Contact(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      accountId: accountId ?? this.accountId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    jobTitle,
    accountId,
  ];
}
