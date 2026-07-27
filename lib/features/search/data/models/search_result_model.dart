import '../../domain/entities/search_result.dart';

/// Tolerant parser for a single `/search` hit.
///
/// **Field resolution order:**
///
/// *Type* (what kind of entity this is):
///   `type` | `entity_type` | `result_type` | `kind`
///   — if none present, falls back to `label` (some APIs put the type there,
///     e.g. `{label: "Deal", name: "Acme Expansion"}`), then [typeHint].
///
/// *Display name* (shown in the dropdown):
///   `name` | `display_name` | `full_name` | `title` | `company` | `text`
///   — checked **before** `label` because some APIs use `label` for the
///     entity type, not the human-readable name.
///   — `label` is used as a last-resort display value only when none of
///     the above are present.
///
/// *Id*: int or numeric string.
SearchResult searchResultFromJson(
  Map<String, dynamic> json, {
  SearchResultType? typeHint,
}) {
  // ── Type resolution ──────────────────────────────────────────────────────
  final rawType = (json['type'] ??
          json['entity_type'] ??
          json['result_type'] ??
          json['kind'] ??
          '')
      .toString();

  // When no dedicated type key exists, `label` may carry the type string
  // (e.g. API returns {id, label: "Deal", name: "Acme Expansion"}).
  final rawTypeFallback =
      rawType.isEmpty ? (json['label'] ?? '').toString() : '';

  final type = rawType.isNotEmpty
      ? searchResultTypeFromWire(rawType)
      : rawTypeFallback.isNotEmpty
          ? searchResultTypeFromWire(rawTypeFallback)
          : (typeHint ?? SearchResultType.unknown);

  // ── Display name resolution ──────────────────────────────────────────────
  // Prefer explicit name fields over `label`, because some APIs repurpose
  // `label` for the entity type rather than the human-readable display name.
  final displayName = (json['name'] ??
          json['display_name'] ??
          json['full_name'] ??
          json['title'] ??
          json['company'] ??
          json['text'] ??
          json['label'] ??   // last-resort: plain label when no name field
          '')
      .toString();

  return SearchResult(type: type, id: _asInt(json['id']), label: displayName);
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
