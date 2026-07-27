import '../../../roles/domain/entities/role.dart';
import '../../domain/entities/user.dart';

/// User model with JSON serialization — data layer.
/// `accessToken`/`refreshToken` are carried alongside the resolved user
/// after login; neither is part of the backend's `UserRead` shape and both
/// are dropped by [toJson] (which is only used for caching the user, not
/// for outgoing requests) — tokens are persisted separately.
class UserModel {
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
  final List<String> permissions;
  final String? accessToken;
  final String? refreshToken;

  const UserModel({
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
    this.accessToken,
    this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: Role.fromJson(json['role'] as Map<String, dynamic>),
      isActive: json['is_active'] as bool? ?? true,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      // Top-level `permissions` — present on the login response and on the
      // cached-user round-trip; absent on plain `/users/me` (⇒ empty).
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  /// Only used to cache the resolved user locally — never sent on the wire,
  /// so the nested role only needs enough to round-trip through
  /// [UserModel.fromJson] again (which is all `Role.fromJson` needs).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'role': {
        'id': role.id,
        'name': role.name,
        'description': role.description,
        'permissions': role.permissions
            .map((p) => {
                  'id': p.id,
                  'code': p.code,
                  'label': p.label,
                  'description': p.description,
                  'module': p.module,
                })
            .toList(),
      },
      'is_active': isActive,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'permissions': permissions,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      role: role,
      isActive: isActive,
      status: status,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      permissions: permissions,
    );
  }
}
