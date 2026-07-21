import 'package:equatable/equatable.dart';

/// User entity — domain layer, no JSON logic.
/// Mirrors backend `UserRead` (app/schemas/user.py): id, email, first_name,
/// last_name, role, is_active.
class User extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String role;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
  });

  String get name =>
      [firstName, lastName].where((p) => p != null && p.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [id, email, firstName, lastName, role, isActive];
}
