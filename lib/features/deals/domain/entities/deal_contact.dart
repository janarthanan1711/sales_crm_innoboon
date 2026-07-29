import 'package:equatable/equatable.dart';

/// A contact linked to a deal, as returned inline by the `/deals` endpoints:
/// `"contacts": [{ "id": 4, "name": "Pam Beesley" }]`.
///
/// Reads carry the resolved display [name]; writes still send bare
/// `contact_ids` (see `DealModel.toCreateJson`/`toUpdateJson`).
class DealContact extends Equatable {
  final int id;
  final String name;

  const DealContact({required this.id, required this.name});

  factory DealContact.fromJson(Map<String, dynamic> json) {
    return DealContact(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  @override
  List<Object?> get props => [id, name];
}
