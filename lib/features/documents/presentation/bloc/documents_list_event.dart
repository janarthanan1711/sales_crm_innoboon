import 'package:equatable/equatable.dart';

abstract class DocumentsListEvent extends Equatable {
  const DocumentsListEvent();
  @override
  List<Object?> get props => [];
}

class DocumentsListLoadRequested extends DocumentsListEvent {
  const DocumentsListLoadRequested();
}
