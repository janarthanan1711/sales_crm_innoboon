import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_leads_usecase.dart';
import 'leads_list_event.dart';
import 'leads_list_state.dart';
export 'leads_list_event.dart';
export 'leads_list_state.dart';

class LeadsListBloc extends Bloc<LeadsListEvent, LeadsListState> {
  final GetLeadsUseCase getLeadsUseCase;

  String? _search;
  String? _statusFilter;
  String? _tierFilter;
  String? _ownerFilter;
  String? _sourceFilter;

  LeadsListBloc({required this.getLeadsUseCase})
    : super(const LeadsListInitial()) {
    on<LeadsListLoadRequested>(_onLoadRequested);
    on<LeadsListSearchChanged>(_onSearchChanged);
    on<LeadsListFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoadRequested(
    LeadsListLoadRequested event,
    Emitter<LeadsListState> emit,
  ) async {
    emit(const LeadsListLoading());
    await _loadLeads(emit);
  }

  Future<void> _onSearchChanged(
    LeadsListSearchChanged event,
    Emitter<LeadsListState> emit,
  ) async {
    _search = event.query;
    await _loadLeads(emit);
  }

  Future<void> _onFilterChanged(
    LeadsListFilterChanged event,
    Emitter<LeadsListState> emit,
  ) async {
    if (event.status != null) _statusFilter = event.status;
    if (event.tier != null) _tierFilter = event.tier;
    if (event.owner != null) _ownerFilter = event.owner;
    if (event.source != null) _sourceFilter = event.source;
    await _loadLeads(emit);
  }

  Future<void> _loadLeads(Emitter<LeadsListState> emit) async {
    final result = await getLeadsUseCase(
      GetLeadsParams(
        search: _search,
        status: _statusFilter,
        tier: _tierFilter,
        owner: _ownerFilter,
        source: _sourceFilter,
      ),
    );

    result.fold(
      (failure) => emit(LeadsListError(failure.message)),
      (leads) => emit(
        LeadsListLoaded(
          leads: leads,
          search: _search,
          statusFilter: _statusFilter,
          tierFilter: _tierFilter,
          ownerFilter: _ownerFilter,
          sourceFilter: _sourceFilter,
        ),
      ),
    );
  }
}
