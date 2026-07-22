import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_accounts_usecase.dart';
import 'accounts_list_event.dart';
import 'accounts_list_state.dart';
export 'accounts_list_event.dart';
export 'accounts_list_state.dart';

class AccountsListBloc extends Bloc<AccountsListEvent, AccountsListState> {
  final GetAccountsUseCase getAccountsUseCase;

  String? _search;
  String? _industryFilter;
  String? _tierFilter;
  int? _ownerFilter;
  int _limit = 25;
  int _offset = 0;

  AccountsListBloc({required this.getAccountsUseCase})
    : super(const AccountsListInitial()) {
    on<AccountsListLoadRequested>(_onLoadRequested);
    on<AccountsListSearchChanged>(_onSearchChanged);
    on<AccountsListFilterChanged>(_onFilterChanged);
    on<AccountsListPageChanged>(_onPageChanged);
    on<AccountsListRowsPerPageChanged>(_onRowsPerPageChanged);
  }

  Future<void> _onLoadRequested(
    AccountsListLoadRequested event,
    Emitter<AccountsListState> emit,
  ) async {
    emit(const AccountsListLoading());
    await _loadAccounts(emit);
  }

  Future<void> _onSearchChanged(
    AccountsListSearchChanged event,
    Emitter<AccountsListState> emit,
  ) async {
    _search = event.query;
    _offset = 0; // new query → back to first page
    await _loadAccounts(emit);
  }

  Future<void> _onFilterChanged(
    AccountsListFilterChanged event,
    Emitter<AccountsListState> emit,
  ) async {
    if (event.industry != null) _industryFilter = event.industry;
    if (event.tier != null) _tierFilter = event.tier;
    if (event.ownerId == AccountsListFilterChanged.clearOwner) {
      _ownerFilter = null;
    } else if (event.ownerId is int) {
      _ownerFilter = event.ownerId as int;
    }
    _offset = 0;
    await _loadAccounts(emit);
  }

  Future<void> _onPageChanged(
    AccountsListPageChanged event,
    Emitter<AccountsListState> emit,
  ) async {
    _offset = event.offset < 0 ? 0 : event.offset;
    await _loadAccounts(emit);
  }

  Future<void> _onRowsPerPageChanged(
    AccountsListRowsPerPageChanged event,
    Emitter<AccountsListState> emit,
  ) async {
    _limit = event.limit;
    _offset = 0;
    await _loadAccounts(emit);
  }

  Future<void> _loadAccounts(Emitter<AccountsListState> emit) async {
    final result = await getAccountsUseCase(
      GetAccountsParams(
        search: _search,
        industry: _industryFilter,
        tier: _tierFilter,
        ownerId: _ownerFilter,
        limit: _limit,
        offset: _offset,
      ),
    );

    result.fold(
      (f) => emit(AccountsListError(f.message)),
      (page) => emit(
        AccountsListLoaded(
          accounts: page.items,
          total: page.total,
          limit: _limit,
          offset: _offset,
          search: _search,
          industryFilter: _industryFilter,
          tierFilter: _tierFilter,
          ownerFilter: _ownerFilter,
        ),
      ),
    );
  }
}
