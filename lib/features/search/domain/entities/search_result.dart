import 'package:equatable/equatable.dart';

enum SearchResultType { lead, account, deal, contact, unknown }

SearchResultType searchResultTypeFromWire(String wire) {
  switch (wire) {
    case 'lead':
      return SearchResultType.lead;
    case 'account':
      return SearchResultType.account;
    case 'deal':
      return SearchResultType.deal;
    case 'contact':
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
