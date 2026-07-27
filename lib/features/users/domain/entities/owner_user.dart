import 'package:equatable/equatable.dart';
import '../../../roles/domain/entities/role.dart';

/// User entity as seen via `GET /users` — used both for lightweight
/// owner-assignment dropdowns (leads/accounts/deals) and for the Admin
/// Settings "Users" tab, since both read the exact same endpoint.
/// Intentionally separate from the auth `User` entity, which additionally
/// carries session-specific meaning (see that entity's doc comment).
class OwnerUser extends Equatable {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatarUrl;
  final Role role;
  final bool isActive;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const OwnerUser({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatarUrl,
    required this.role,
    required this.isActive,
    this.status = 'active',
    this.createdAt,
    this.lastLoginAt,
  });

  /// Display name shown in dropdowns — "FirstName LastName" or just
  /// "FirstName" when last name is null.
  String get displayName =>
      lastName != null ? '$firstName $lastName' : firstName;

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    phoneNumber,
    avatarUrl,
    role,
    isActive,
    status,
    createdAt,
    lastLoginAt,
  ];
}
