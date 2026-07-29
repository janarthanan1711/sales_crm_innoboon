import 'package:equatable/equatable.dart';

/// A contact linked to a deal, as returned inline by the `/deals` endpoints:
/// `"contacts": [{ "id": 3, "name": "Jim Halpert", "email": "jim@gmail.com",
/// "phone": "7894561233" }]`.
///
/// [email] and [phone] are nullable — the API sends `null` for contacts that
/// don't have them recorded. Reads carry these resolved display fields; writes
/// still send bare `contact_ids` (see `DealModel.toCreateJson`/`toUpdateJson`).
class DealContact extends Equatable {
  final int id;
  final String name;
  final String? email;
  final String? phone;

  const DealContact({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory DealContact.fromJson(Map<String, dynamic> json) {
    return DealContact(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      email: _clean(json['email']),
      phone: _clean(json['phone']),
    );
  }

  /// Treats missing, null, and whitespace-only values alike so the UI only has
  /// to check for null.
  static String? _clean(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool get hasEmail => email != null;
  bool get hasPhone => phone != null;

  @override
  List<Object?> get props => [id, name, email, phone];
}
