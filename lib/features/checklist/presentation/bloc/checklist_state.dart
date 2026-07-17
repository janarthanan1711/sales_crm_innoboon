import 'package:equatable/equatable.dart';
import '../../domain/entities/checklist_item.dart';

abstract class ChecklistState extends Equatable {
  const ChecklistState();
  @override
  List<Object?> get props => [];
}

class ChecklistInitial extends ChecklistState {
  const ChecklistInitial();
}

class ChecklistLoading extends ChecklistState {
  const ChecklistLoading();
}

class ChecklistLoaded extends ChecklistState {
  final List<ChecklistStage> stages;
  const ChecklistLoaded(this.stages);
  @override
  List<Object?> get props => [stages];
}

class ChecklistError extends ChecklistState {
  final String message;
  const ChecklistError(this.message);
  @override
  List<Object?> get props => [message];
}
