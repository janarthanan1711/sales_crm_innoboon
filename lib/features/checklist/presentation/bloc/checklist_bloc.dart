import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/checklist_usecases.dart';
import 'checklist_event.dart';
import 'checklist_state.dart';
export 'checklist_event.dart';
export 'checklist_state.dart';

class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final GetChecklistForDealUseCase getChecklistForDealUseCase;
  final ToggleChecklistItemUseCase toggleChecklistItemUseCase;
  
  String? _currentDealId;

  ChecklistBloc({
    required this.getChecklistForDealUseCase,
    required this.toggleChecklistItemUseCase,
  }) : super(const ChecklistInitial()) {
    on<ChecklistLoadForDealRequested>((event, emit) async {
      _currentDealId = event.dealId;
      emit(const ChecklistLoading());
      final result = await getChecklistForDealUseCase(event.dealId);
      result.fold((f) => emit(ChecklistError(f.message)), (s) => emit(ChecklistLoaded(s)));
    });

    on<ChecklistItemToggled>((event, emit) async {
      // Optimistic update logic would go here, but for simplicity:
      final result = await toggleChecklistItemUseCase(ToggleChecklistItemParams(
        itemId: event.itemId,
        isCompleted: event.isCompleted,
      ));
      
      result.fold(
        (f) => emit(ChecklistError(f.message)), // On error, show error
        (item) async {
          // On success, reload checklist
          if (_currentDealId != null) {
            final reloadResult = await getChecklistForDealUseCase(_currentDealId!);
            reloadResult.fold((f) => emit(ChecklistError(f.message)), (s) => emit(ChecklistLoaded(s)));
          }
        }
      );
    });
  }
}
