import '../../domain/entities/search_result.dart';

SearchResult searchResultFromJson(Map<String, dynamic> json) {
  return SearchResult(
    type: searchResultTypeFromWire(json['type'] as String? ?? ''),
    id: json['id'] as int,
    label: json['label'] as String? ?? '',
  );
}
