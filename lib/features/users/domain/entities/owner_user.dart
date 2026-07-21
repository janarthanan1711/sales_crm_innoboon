import 'package:equatable/equatable.dart';

/// Lightweight user entity for owner assignment dropdowns.
/// Intentionally separate from the auth `User` entity — this carries no
/// tokens and is populated from `GET /users` (available to any
/// authenticated role).
class OwnerUser extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String role;
  final bool isActive;

  const OwnerUser({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
  });

  /// Display name shown in dropdowns — "FirstName LastName" or just
  /// "FirstName" when last name is null.
  String get displayName =>
      lastName != null ? '$firstName $lastName' : firstName;

  @override
  List<Object?> get props => [id, email, firstName, lastName, role, isActive];
}
