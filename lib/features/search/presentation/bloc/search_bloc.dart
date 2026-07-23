import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/global_search_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';
export 'search_event.dart';
export 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GlobalSearchUseCase globalSearchUseCase;

  SearchBloc({required this.globalSearchUseCase}) : super(const SearchInitial()) {
    on<SearchQuerySubmitted>(_onQuerySubmitted);
    on<SearchCleared>(_onCleared);
  }

  Future<void> _onQuerySubmitted(SearchQuerySubmitted event, Emitter<SearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(const SearchInitial());
      return;
    }
    emit(SearchLoading(query));
    final result = await globalSearchUseCase(query);
    // Ignore a stale response if the query moved on while awaiting.
    final current = state;
    if (current is SearchLoading && current.query != query) return;
    result.fold(
      (f) => emit(SearchError(f.message)),
      (results) => emit(SearchLoaded(query: query, results: results)),
    );
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchInitial());
  }
}
