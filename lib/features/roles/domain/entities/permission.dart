import 'package:equatable/equatable.dart';

/// A single permission catalog entry — mirrors `GET /permissions`.
class Permission extends Equatable {
  final int id;
  final String code;
  final String label;
  final String description;
  final String module;

  const Permission({
    required this.id,
    required this.code,
    required this.label,
    this.description = '',
    this.module = '',
  });

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      module: json['module'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, code, label, description, module];
}
