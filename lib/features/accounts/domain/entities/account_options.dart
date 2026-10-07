/// Dropdown options for Account country / engagement type, served by
/// `GET /accounts/options` (never hardcoded in the app).
class AccountOptions {
  final List<String> countries;

  /// key -> label, in display order.
  final Map<String, String> engagementTypes;

  const AccountOptions({
    required this.countries,
    required this.engagementTypes,
  });

  factory AccountOptions.fromJson(Map<String, dynamic> json) => AccountOptions(
    countries: (json['countries'] as List<dynamic>).cast<String>(),
    engagementTypes: {
      for (final e in json['engagement_types'] as List<dynamic>)
        (e as Map<String, dynamic>)['key'] as String: e['label'] as String,
    },
  );
}
