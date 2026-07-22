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
  String? _ownerFilter;

  AccountsListBloc({required this.getAccountsUseCase})
    : super(const AccountsListInitial()) {
    on<AccountsListLoadRequested>(_onLoadRequested);
    on<AccountsListSearchChanged>(_onSearchChanged);
    on<AccountsListFilterChanged>(_onFilterChanged);
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
    await _loadAccounts(emit);
  }

  Future<void> _onFilterChanged(
    AccountsListFilterChanged event,
    Emitter<AccountsListState> emit,
  ) async {
    if (event.industry != null) _industryFilter = event.industry;
    if (event.tier != null) _tierFilter = event.tier;
    if (event.owner != null) _ownerFilter = event.owner;
    await _loadAccounts(emit);
  }

  Future<void> _loadAccounts(Emitter<AccountsListState> emit) async {
    final result = await getAccountsUseCase(
      GetAccountsParams(
        search: _search,
        industry: _industryFilter,
        tier: _tierFilter,
      ),
    );

    result.fold(
      (f) => emit(AccountsListError(f.message)),
      (a) => emit(
        AccountsListLoaded(
          accounts: a,
          search: _search,
          industryFilter: _industryFilter,
          tierFilter: _tierFilter,
          ownerFilter: _ownerFilter,
        ),
      ),
    );
  }
}
