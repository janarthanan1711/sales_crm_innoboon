import '../../domain/entities/search_result.dart';

/// Tolerant parser for a single `/search` hit. The backend contract is
/// `{type, id, label}`, but we accept common field-name variants so a minor
/// shape difference doesn't leave the dropdown blank:
///  - type:  `type` | `entity_type` | `result_type` | `kind`
///  - label: `label` | `name` | `title` | `display_name` | `full_name` |
///           `company` | `text`
///  - id:    int or numeric string
SearchResult searchResultFromJson(
  Map<String, dynamic> json, {
  SearchResultType? typeHint,
}) {
  final rawType = (json['type'] ??
          json['entity_type'] ??
          json['result_type'] ??
          json['kind'] ??
          '')
      .toString();
  final type = rawType.isNotEmpty
      ? searchResultTypeFromWire(rawType)
      : (typeHint ?? SearchResultType.unknown);

  final label = (json['label'] ??
          json['name'] ??
          json['title'] ??
          json['display_name'] ??
          json['full_name'] ??
          json['company'] ??
          json['text'] ??
          '')
      .toString();

  return SearchResult(type: type, id: _asInt(json['id']), label: label);
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
