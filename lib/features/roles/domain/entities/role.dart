import 'package:equatable/equatable.dart';
import 'permission.dart';

/// A role — mirrors `RoleRead` (see `GET/POST/PATCH /roles`), and is also
/// the shape nested under `role` on every user object (`GET /users`,
/// `GET /users/me`, etc).
class Role extends Equatable {
  final int id;
  final String name;
  final String description;
  final List<Permission> permissions;

  const Role({
    required this.id,
    required this.name,
    this.description = '',
    this.permissions = const [],
  });

  bool hasPermission(String code) => permissions.any((p) => p.code == code);

  factory Role.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'] as List<dynamic>? ?? const [];
    return Role(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      permissions: rawPermissions
          .map((p) => Permission.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, permissions];
}
