import '../../domain/entities/lead_import_result.dart';

LeadImportResult leadImportResultFromJson(Map<String, dynamic> json) {
  final rawErrors = json['errors'] as List<dynamic>? ?? const [];
  return LeadImportResult(
    created: json['created'] as int? ?? 0,
    errors: rawErrors.map((e) {
      final m = e as Map<String, dynamic>;
      return LeadImportRowError(
        row: m['row'] as int? ?? 0,
        error: m['error'] as String? ?? 'Unknown error',
      );
    }).toList(),
  );
}
