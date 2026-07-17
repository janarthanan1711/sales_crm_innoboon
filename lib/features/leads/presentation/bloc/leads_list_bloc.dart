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
  String? _sourceFilter;
  int? _ownerIdFilter;

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
    _statusFilter = event.status;
    _sourceFilter = event.source;
    _ownerIdFilter = event.ownerId;
    await _loadLeads(emit);
  }

  Future<void> _loadLeads(Emitter<LeadsListState> emit) async {
    final result = await getLeadsUseCase(
      GetLeadsParams(
        search: _search,
        status: _statusFilter,
        source: _sourceFilter,
        ownerId: _ownerIdFilter,
      ),
    );

    result.fold(
      (failure) => emit(LeadsListError(failure.message)),
      (page) => emit(
        LeadsListLoaded(
          leads: page.items,
          total: page.total,
          search: _search,
          statusFilter: _statusFilter,
          sourceFilter: _sourceFilter,
          ownerIdFilter: _ownerIdFilter,
        ),
      ),
    );
  }
}
