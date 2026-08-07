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
  int? _stageId;
  List<DealStageDef> _stages = const [];

  DealsListBloc({
    required this.getDealsUseCase,
    required this.getDealStagesUseCase,
    required this.updateDealStageUseCase,
    required this.getAccountsUseCase,
    required this.getUsersUseCase,
  }) : super(const DealsListInitial()) {
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
      _stageId = event.stageId;
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
      GetDealsParams(ownerId: _ownerId, stageId: _stageId),
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
