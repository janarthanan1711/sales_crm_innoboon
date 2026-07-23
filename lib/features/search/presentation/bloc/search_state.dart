import 'package:equatable/equatable.dart';
import '../../domain/entities/search_result.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  final String query;
  const SearchLoading(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchLoaded extends SearchState {
  final String query;
  final List<SearchResult> results;
  const SearchLoaded({required this.query, required this.results});

  List<SearchResult> ofType(SearchResultType type) =>
      results.where((r) => r.type == type).toList();

  @override
  List<Object?> get props => [query, results];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}
