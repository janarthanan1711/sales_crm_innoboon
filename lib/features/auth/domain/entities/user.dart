import 'package:equatable/equatable.dart';
import '../../../roles/domain/entities/role.dart';

/// User entity — domain layer, no JSON logic.
/// Mirrors backend `UserRead` (see `GET /users/me`, `GET /users`): id,
/// email, first_name, last_name, phone_number, avatar_url, role (nested
/// object with permissions), is_active, status, created_at, last_login_at.
class User extends Equatable {
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

  const User({
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

  String get name =>
      [firstName, lastName].where((p) => p != null && p.isNotEmpty).join(' ');

  bool hasPermission(String code) => role.hasPermission(code);

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
