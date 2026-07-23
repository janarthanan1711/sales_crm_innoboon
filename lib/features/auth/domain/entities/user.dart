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

  /// The caller's effective permission codes, from the login response's
  /// top-level `permissions` array. This — NOT `role.permissions` (which the
  /// `/users/me` response returns empty) — is the authoritative source used
  /// for gating UI (e.g. the sidebar).
  final List<String> permissions;

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
    this.permissions = const [],
  });

  String get name =>
      [firstName, lastName].where((p) => p != null && p.isNotEmpty).join(' ');

  bool hasPermission(String code) =>
      permissions.contains(code) || role.hasPermission(code);

  /// True if the user holds any one of [codes] (empty ⇒ always true).
  bool hasAnyPermission(List<String> codes) =>
      codes.isEmpty || codes.any(hasPermission);

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
    permissions,
  ];
}
