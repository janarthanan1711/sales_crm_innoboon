import '../../domain/entities/contact_import_result.dart';

ContactImportResult contactImportResultFromJson(Map<String, dynamic> json) {
  final rawErrors = json['errors'] as List<dynamic>? ?? const [];
  return ContactImportResult(
    created: json['created'] as int? ?? 0,
    errors: rawErrors.map((e) {
      final m = e as Map<String, dynamic>;
      return ContactImportRowError(
        row: m['row'] as int? ?? 0,
        error: m['error'] as String? ?? 'Unknown error',
      );
    }).toList(),
  );
}
