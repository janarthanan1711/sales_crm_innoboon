import 'package:equatable/equatable.dart';

enum SearchResultType { lead, account, deal, contact, unknown }

/// Maps a wire `type` value to [SearchResultType], tolerant of casing and
/// singular/plural (e.g. `"Lead"`, `"leads"`, `"LEAD"` all map to `lead`) so
/// results aren't silently dropped when the backend labels differ slightly.
SearchResultType searchResultTypeFromWire(String wire) {
  var w = wire.trim().toLowerCase();
  if (w.endsWith('s')) w = w.substring(0, w.length - 1);
  switch (w) {
    case 'lead':
      return SearchResultType.lead;
    case 'account':
    case 'company':
    case 'organization':
      return SearchResultType.account;
    case 'deal':
    case 'opportunity':
      return SearchResultType.deal;
    case 'contact':
    case 'person':
      return SearchResultType.contact;
    default:
      return SearchResultType.unknown;
  }
}

/// One hit from `GET /search?q=` — the API returns only `{type, id, label}`,
/// so that's all this carries (no tier/stage badges, which aren't in the
/// contract).
class SearchResult extends Equatable {
  final SearchResultType type;
  final int id;
  final String label;

  const SearchResult({required this.type, required this.id, required this.label});

  @override
  List<Object?> get props => [type, id, label];
}
