import 'package:equatable/equatable.dart';

class Stakeholder extends Equatable {
  final String id;
  final String name;
  final String role;
  final String email;
  final String dealId;
  final bool isPrimary;

  const Stakeholder({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.dealId,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [id, name, role, email, dealId, isPrimary];
}
