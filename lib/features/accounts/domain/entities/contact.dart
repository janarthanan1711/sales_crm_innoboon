import 'package:equatable/equatable.dart';

class Contact extends Equatable {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? phone;
  final bool isDecisionMaker;
  final String accountId;

  const Contact({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.phone,
    this.isDecisionMaker = false,
    required this.accountId,
  });

  @override
  List<Object?> get props => [id, name, role, email, phone, isDecisionMaker, accountId];
}
