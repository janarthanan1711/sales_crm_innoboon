import '../../domain/entities/user.dart';

/// User model with JSON serialization — data layer.
/// `accessToken` is carried alongside the resolved user after login; it is
/// never part of the backend's `UserRead` shape and is dropped by [toJson]
/// (which is only used for caching the user, not for outgoing requests).
class UserModel {
  final int id;
  final String email;
  final String firstName;
  final String? lastName;
  final String role;
  final bool isActive;
  final String? accessToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    this.lastName,
    required this.role,
    required this.isActive,
    this.accessToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      accessToken: json['access_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'is_active': isActive,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      isActive: isActive,
    );
  }
}
