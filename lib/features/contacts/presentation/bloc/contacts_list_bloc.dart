import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/contact_usecases.dart';
import 'contacts_list_event.dart';
import 'contacts_list_state.dart';
export 'contacts_list_event.dart';
export 'contacts_list_state.dart';

class ContactsListBloc extends Bloc<ContactsListEvent, ContactsListState> {
  final GetContactsUseCase getContactsUseCase;
  final DeleteContactUseCase deleteContactUseCase;

  String? _search;
  int? _ownerFilter;
  int? _accountFilter;
  String? _tierFilter;
  bool _primaryOnly = false;
  int _limit = 10;
  int _offset = 0;

  ContactsListBloc({
    required this.getContactsUseCase,
    required this.deleteContactUseCase,
  }) : super(const ContactsListInitial()) {
    on<ContactsListLoadRequested>(_onLoad);
    on<ContactsListSearchChanged>(_onSearch);
    on<ContactsListFilterChanged>(_onFilter);
    on<ContactsListCleared>(_onCleared);
    on<ContactsListPageChanged>(_onPage);
    on<ContactsListRowsPerPageChanged>(_onRows);
    on<ContactsListDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(ContactsListLoadRequested event, Emitter<ContactsListState> emit) async {
    emit(const ContactsListLoading());
    await _load(emit);
  }

  Future<void> _onSearch(ContactsListSearchChanged event, Emitter<ContactsListState> emit) async {
    _search = event.query;
    _offset = 0;
    await _load(emit);
  }

  Future<void> _onFilter(ContactsListFilterChanged event, Emitter<ContactsListState> emit) async {
    if (event.ownerId == ContactsListFilterChanged.clearOwner) {
      _ownerFilter = null;
    } else if (event.ownerId is int) {
      _ownerFilter = event.ownerId as int;
    }
    if (event.accountId == ContactsListFilterChanged.clearAccount) {
      _accountFilter = null;
    } else if (event.accountId is int) {
      _accountFilter = event.accountId as int;
    }
    if (event.tier != null) {
      _tierFilter = event.tier == 'all' ? null : event.tier;
    }
    if (event.isPrimary != null) _primaryOnly = event.isPrimary!;
    _offset = 0;
    await _load(emit);
  }

  Future<void> _onCleared(ContactsListCleared event, Emitter<ContactsListState> emit) async {
    _search = null;
    _ownerFilter = null;
    _accountFilter = null;
    _tierFilter = null;
    _primaryOnly = false;
    _offset = 0;
    await _load(emit);
  }

  Future<void> _onPage(ContactsListPageChanged event, Emitter<ContactsListState> emit) async {
    _offset = event.offset < 0 ? 0 : event.offset;
    await _load(emit);
  }

  Future<void> _onRows(ContactsListRowsPerPageChanged event, Emitter<ContactsListState> emit) async {
    _limit = event.limit;
    _offset = 0;
    await _load(emit);
  }

  Future<void> _onDelete(ContactsListDeleteRequested event, Emitter<ContactsListState> emit) async {
    String? error;
    for (final id in event.ids) {
      final result = await deleteContactUseCase(id);
      result.fold((f) => error ??= f.message, (_) {});
    }
    // If we deleted the whole last page, step back one page.
    if (_offset >= event.ids.length && _offset > 0) {
      final remaining = (state is ContactsListLoaded)
          ? (state as ContactsListLoaded).total - event.ids.length
          : 0;
      if (_offset >= remaining) {
        _offset = (_offset - _limit) < 0 ? 0 : _offset - _limit;
      }
    }
    await _load(emit, actionError: error);
  }

  Future<void> _load(Emitter<ContactsListState> emit, {String? actionError}) async {
    final result = await getContactsUseCase(GetContactsParams(
      ownerId: _ownerFilter,
      accountId: _accountFilter,
      tier: _tierFilter,
      isPrimary: _primaryOnly ? true : null,
      search: _search,
      limit: _limit,
      offset: _offset,
    ));

    result.fold(
      (f) => emit(ContactsListError(f.message)),
      (page) => emit(ContactsListLoaded(
        contacts: page.items,
        total: page.total,
        limit: _limit,
        offset: _offset,
        search: _search,
        ownerFilter: _ownerFilter,
        accountFilter: _accountFilter,
        tierFilter: _tierFilter,
        primaryOnly: _primaryOnly,
        actionError: actionError,
      )),
    );
  }
}
