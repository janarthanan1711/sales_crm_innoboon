import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/document_usecases.dart';
import 'documents_list_event.dart';
import 'documents_list_state.dart';
export 'documents_list_event.dart';
export 'documents_list_state.dart';

class DocumentsListBloc extends Bloc<DocumentsListEvent, DocumentsListState> {
  final GetDocumentsUseCase getDocumentsUseCase;

  DocumentsListBloc({required this.getDocumentsUseCase})
    : super(const DocumentsListInitial()) {
    on<DocumentsListLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    DocumentsListLoadRequested event,
    Emitter<DocumentsListState> emit,
  ) async {
    emit(const DocumentsListLoading());
    // Fetch the full, visibility-scoped union once; source/search filtering
    // happens client-side (the list isn't paginated).
    final result = await getDocumentsUseCase(const GetDocumentsParams());
    result.fold(
      (f) => emit(DocumentsListError(f.message)),
      (docs) => emit(DocumentsListLoaded(docs)),
    );
  }
}
