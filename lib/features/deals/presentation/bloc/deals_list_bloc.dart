import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../accounts/domain/usecases/get_accounts_usecase.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/usecases/get_deals_usecase.dart';
import '../../domain/usecases/get_deal_stages_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import 'deals_list_event.dart';
import 'deals_list_state.dart';
export 'deals_list_event.dart';
export 'deals_list_state.dart';

class DealsListBloc extends Bloc<DealsListEvent, DealsListState> {
  final GetDealsUseCase getDealsUseCase;
  final GetDealStagesUseCase getDealStagesUseCase;
  final UpdateDealStageUseCase updateDealStageUseCase;
  final GetAccountsUseCase getAccountsUseCase;
  final GetUsersUseCase getUsersUseCase;

  int? _ownerId;
  List<int>? _stageId;
  List<DealStageDef> _stages = const [];

  // Drill-down filters set once from a dashboard tile tap (Deals in
  // Pipeline / Deals Closed). `_dateFrom`/`_dateTo` double as the on-page
  // range a rep can pick after load (see `hasDrillDownDateRange` below for
  // how the two stay from colliding). `_dateField` is always `closed_at` in
  // practice -- the page used to let a rep toggle it to `created_at`, but
  // that meant a range could show a different count than the dashboard's
  // Deals Closed tile for the same dates. It stays mutable (rather than a
  // constant) only so it can still arrive via the constructor unchanged from
  // a drill-down.
  String? _dateField;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  final String? _stageState;

  /// True when this bloc was constructed with a drill-down date range — the
  /// on-page date picker hides itself in that case rather than fighting over
  /// which range is active. Captured once at construction, not re-derived
  /// from `_dateFrom`/`_dateTo`, since those become mutable below.
  final bool hasDrillDownDateRange;

  DealsListBloc({
    required this.getDealsUseCase,
    required this.getDealStagesUseCase,
    required this.updateDealStageUseCase,
    required this.getAccountsUseCase,
    required this.getUsersUseCase,
    String? dateField,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? stageState,
  }) : _dateField = dateField,
       _dateFrom = dateFrom,
       _dateTo = dateTo,
       _stageState = stageState,
       hasDrillDownDateRange = dateFrom != null || dateTo != null,
       super(const DealsListInitial()) {
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
    if (event.clearOwner) {
      _ownerId = null;
    } else if (event.ownerId != null) {
      _ownerId = event.ownerId;
    }
    if (event.clearStage) {
      _stageId = null;
    } else if (event.stageId != null) {
      _stageId = event.stageId!.isEmpty ? null : event.stageId;
    }
    if (event.clearDate) {
      _dateFrom = null;
      _dateTo = null;
    } else if (event.dateFrom != null || event.dateTo != null) {
      _dateFrom = event.dateFrom;
      _dateTo = event.dateTo;
    }
    if (event.dateField != null) {
      _dateField = event.dateField;
    }
    await _loadDeals(emit);
  }

  Future<void> _onStageUpdated(
    DealsListStageUpdated event,
    Emitter<DealsListState> emit,
  ) async {
    if (state is! DealsListLoaded) return;
    final currentState = state as DealsListLoaded;
    final previousDeals = currentState.deals;

    final newStage = _stageById(event.newStageId);
    // Optimistic update so the drag feels instant.
    final optimisticDeals = previousDeals
        .map(
          (d) => d.id == event.dealId
              ? d.copyWith(
                  stageId: event.newStageId,
                  stageName: newStage?.name ?? d.stageName,
                  stageIsCold: newStage?.isCold ?? d.stageIsCold,
                )
              : d,
        )
        .toList();
    emit(
      DealsListLoaded(
        deals: optimisticDeals,
        stages: currentState.stages,
        ownerIdFilter: currentState.ownerIdFilter,
        stageIdFilter: currentState.stageIdFilter,
        dateFromFilter: currentState.dateFromFilter,
        dateToFilter: currentState.dateToFilter,
      ),
    );

    final result = await updateDealStageUseCase(
      UpdateDealStageParams(
        id: event.dealId,
        stageId: event.newStageId,
        note: event.note,
        coldReason: event.coldReason,
      ),
    );

    result.fold(
      (failure) => emit(
        DealsListLoaded(
          deals: previousDeals,
          stages: currentState.stages,
          ownerIdFilter: currentState.ownerIdFilter,
          stageIdFilter: currentState.stageIdFilter,
          dateFromFilter: currentState.dateFromFilter,
          dateToFilter: currentState.dateToFilter,
          actionError: 'Failed to move deal: ${failure.message}',
        ),
      ),
      (updatedDeal) => emit(
        DealsListLoaded(
          deals: optimisticDeals
              .map(
                (d) => d.id == updatedDeal.id
                    ? _resolveStage(
                        updatedDeal,
                      ).copyWith(accountName: d.accountName, owner: d.owner)
                    : d,
              )
              .toList(),
          stages: currentState.stages,
          ownerIdFilter: currentState.ownerIdFilter,
          stageIdFilter: currentState.stageIdFilter,
          dateFromFilter: currentState.dateFromFilter,
          dateToFilter: currentState.dateToFilter,
        ),
      ),
    );
  }

  Future<void> _loadDeals(Emitter<DealsListState> emit) async {
    if (_stages.isEmpty) {
      final stagesResult = await getDealStagesUseCase();
      stagesResult.fold((_) {}, (s) => _stages = s);
    }
    final result = await getDealsUseCase(
      GetDealsParams(
        ownerId: _ownerId,
        stageId: _stageId,
        dateField: _dateField,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        stageState: _stageState,
      ),
    );
    await result.fold((f) async => emit(DealsListError(f.message)), (
      deals,
    ) async {
      final enriched = await _enrichDeals(deals);
      emit(
        DealsListLoaded(
          deals: enriched,
          stages: _stages,
          ownerIdFilter: _ownerId,
          stageIdFilter: _stageId,
          dateFromFilter: _dateFrom,
          dateToFilter: _dateTo,
        ),
      );
    });
  }

  DealStageDef? _stageById(int id) {
    final matches = _stages.where((s) => s.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Deal _resolveStage(Deal d) {
    final s = _stageById(d.stageId);
    if (s == null) return d;
    return d.copyWith(stageName: s.name, stageIsCold: s.isCold);
  }

  /// Fills in any display value `GET /deals` didn't already resolve.
  ///
  /// The API now returns `account_name`/`owner_name`/`stage_name` on every
  /// `DealRead` (doc §6.1), so this is normally a no-op and both lookups are
  /// skipped. They stay as a fallback for older builds — and they only ever
  /// narrow the gap, since `GET /accounts` is itself row-scoped and can't
  /// resolve a colleague's account. Whatever the wire supplied always wins.
  Future<List<Deal>> _enrichDeals(List<Deal> deals) async {
    final needsAccount = deals.any((d) => d.accountName.trim().isEmpty);
    final needsOwner = deals.any(
      (d) => d.ownerId != null && d.owner.trim().isEmpty,
    );

    final accountNames = <String, String>{};
    if (needsAccount) {
      final accountsResult = await getAccountsUseCase(
        const GetAccountsParams(limit: 1000),
      );
      accountsResult.fold((_) {}, (page) {
        for (final a in page.items) {
          accountNames[a.id] = a.companyName;
        }
      });
    }
    final ownerNames = <int, String>{};
    if (needsOwner) {
      final usersResult = await getUsersUseCase();
      usersResult.fold((_) {}, (users) {
        for (final u in users) {
          ownerNames[u.id] = u.displayName;
        }
      });
    }

    return deals.map((d) {
      final s = _stageById(d.stageId);
      final wireStage = d.stageName.trim().isNotEmpty;
      return d.copyWith(
        accountName: d.accountName.trim().isNotEmpty
            ? d.accountName
            : (accountNames[d.accountId] ?? d.accountName),
        owner: d.owner.trim().isNotEmpty
            ? d.owner
            : (ownerNames[d.ownerId] ?? d.owner),
        stageName: wireStage ? d.stageName : (s?.name ?? d.stageName),
        stageIsCold: wireStage ? d.stageIsCold : (s?.isCold ?? d.stageIsCold),
      );
    }).toList();
  }
}
