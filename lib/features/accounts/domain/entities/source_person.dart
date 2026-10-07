import 'package:equatable/equatable.dart';

/// A platform User or a Contact, as listed in the Account Source Detail
/// picker and the Deal Originator dropdown (`SourcePersonRead` on the API).
/// [type] is `user` or `contact`; (type, id) identifies the person.
class SourcePerson extends Equatable {
  final String type;
  final int id;
  final String name;
  final String? email;
  final String? phone;

  const SourcePerson({
    required this.type,
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory SourcePerson.fromJson(Map<String, dynamic> json) => SourcePerson(
    type: json['type'] as String,
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
  );

  /// Unique across users and contacts (their ids overlap).
  String get key => '$type:$id';

  Map<String, dynamic> toRefJson() => {'type': type, 'id': id};

  /// "Name — email · phone", the picker's one-line description.
  String get label {
    final extras = [
      if (email != null && email!.isNotEmpty) email!,
      if (phone != null && phone!.isNotEmpty) phone!,
    ];
    return extras.isEmpty ? name : '$name — ${extras.join(' · ')}';
  }

  @override
  List<Object?> get props => [type, id, name, email, phone];
}
