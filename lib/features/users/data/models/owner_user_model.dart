import '../../domain/entities/owner_user.dart';

/// Model with JSON deserialization for the `GET /users` response shape:
/// ```json
/// {"id": 12, "email": "...", "first_name": "...", "last_name": "...",
///  "role": "sales_rep", "is_active": true}
/// ```
class OwnerUserModel extends OwnerUser {
  const OwnerUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    super.lastName,
    required super.role,
    required super.isActive,
  });

  factory OwnerUserModel.fromJson(Map<String, dynamic> json) {
    return OwnerUserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}
