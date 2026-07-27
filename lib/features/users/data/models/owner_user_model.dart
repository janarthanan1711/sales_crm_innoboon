import '../../../roles/domain/entities/role.dart';
import '../../domain/entities/owner_user.dart';

/// Model with JSON deserialization for the `GET /users` response shape.
class OwnerUserModel extends OwnerUser {
  const OwnerUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    super.lastName,
    super.phoneNumber,
    super.avatarUrl,
    required super.role,
    required super.isActive,
    super.status,
    super.createdAt,
    super.lastLoginAt,
  });

  factory OwnerUserModel.fromJson(Map<String, dynamic> json) {
    return OwnerUserModel(
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
    );
  }
}
