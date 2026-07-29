import 'package:equatable/equatable.dart';
import '../../domain/entities/document.dart';

abstract class DocumentsListState extends Equatable {
  const DocumentsListState();
  @override
  List<Object?> get props => [];
}

class DocumentsListInitial extends DocumentsListState {
  const DocumentsListInitial();
}

class DocumentsListLoading extends DocumentsListState {
  const DocumentsListLoading();
}

class DocumentsListLoaded extends DocumentsListState {
  final List<Document> documents;
  const DocumentsListLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class DocumentsListError extends DocumentsListState {
  final String message;
  const DocumentsListError(this.message);

  @override
  List<Object?> get props => [message];
}
