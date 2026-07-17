import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_deals_usecase.dart';
import 'deals_list_event.dart';
import 'deals_list_state.dart';
export 'deals_list_event.dart';
export 'deals_list_state.dart';

class DealsListBloc extends Bloc<DealsListEvent, DealsListState> {
  final GetDealsUseCase getDealsUseCase;

  String? _ownerFilter;
  String? _tierFilter;

  DealsListBloc({required this.getDealsUseCase})
    : super(const DealsListInitial()) {
    on<DealsListLoadRequested>(_onLoadRequested);
    on<DealsListFilterChanged>(_onFilterChanged);
    on<DealsListStageUpdated>(_onStageUpdated);
  }

  Future<void> _onLoadRequested(
    DealsListLoadRequested event,
    Emitter<DealsListState> emit,
  ) async {
    emit(const DealsListLoading());
    await _loadDeals(emit);
  }

  Future<void> _onFilterChanged(
    DealsListFilterChanged event,
    Emitter<DealsListState> emit,
  ) async {
    if (event.owner != null) _ownerFilter = event.owner;
    if (event.tier != null) _tierFilter = event.tier;
    await _loadDeals(emit);
  }

  Future<void> _onStageUpdated(
    DealsListStageUpdated event,
    Emitter<DealsListState> emit,
  ) async {
    // In a real app, you'd call UpdateDealStageUseCase here, but since the
    // board handles drag-and-drop, we can optimistically update the state
    if (state is DealsListLoaded) {
      final currentState = state as DealsListLoaded;
      final updatedDeals = currentState.deals.map((d) {
        if (d.id == event.dealId) return d.copyWith(stage: event.newStage);
        return d;
      }).toList();
      emit(
        DealsListLoaded(
          deals: updatedDeals,
          ownerFilter: _ownerFilter,
          tierFilter: _tierFilter,
        ),
      );
    }
  }

  Future<void> _loadDeals(Emitter<DealsListState> emit) async {
    final result = await getDealsUseCase(
      GetDealsParams(owner: _ownerFilter, tier: _tierFilter),
    );
    result.fold(
      (f) => emit(DealsListError(f.message)),
      (d) => emit(
        DealsListLoaded(
          deals: d,
          ownerFilter: _ownerFilter,
          tierFilter: _tierFilter,
        ),
      ),
    );
  }
}
