import 'package:equatable/equatable.dart';

/// User entity — domain layer, no JSON logic
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? phone;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, email, role, avatarUrl, phone];
}
