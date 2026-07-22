import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../accounts/domain/usecases/get_accounts_usecase.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/get_deals_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import 'deals_list_event.dart';
import 'deals_list_state.dart';
export 'deals_list_event.dart';
export 'deals_list_state.dart';

class DealsListBloc extends Bloc<DealsListEvent, DealsListState> {
  final GetDealsUseCase getDealsUseCase;
  final UpdateDealStageUseCase updateDealStageUseCase;
  final GetAccountsUseCase getAccountsUseCase;
  final GetUsersUseCase getUsersUseCase;

  int? _ownerId;
  DealStageFilterHolder? _stage;

  DealsListBloc({
    required this.getDealsUseCase,
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
      _stage = null;
    } else if (event.stage != null) {
      _stage = DealStageFilterHolder(event.stage!);
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

    // Optimistic update so the drag feels instant.
    final optimisticDeals = previousDeals
        .map((d) => d.id == event.dealId ? d.copyWith(stage: event.newStage) : d)
        .toList();
    emit(DealsListLoaded(
      deals: optimisticDeals,
      ownerIdFilter: currentState.ownerIdFilter,
      stageFilter: currentState.stageFilter,
    ));

    final result = await updateDealStageUseCase(
      UpdateDealStageParams(id: event.dealId, stage: event.newStage, note: event.note),
    );

    result.fold(
      (failure) => emit(DealsListLoaded(
        deals: previousDeals,
        ownerIdFilter: currentState.ownerIdFilter,
        stageFilter: currentState.stageFilter,
        actionError: 'Failed to move deal: ${failure.message}',
      )),
      (updatedDeal) => emit(DealsListLoaded(
        // Preserve the client-resolved account/owner display names — the
        // server response only carries account_id/owner_id, not names.
        deals: optimisticDeals
            .map((d) => d.id == updatedDeal.id
                ? updatedDeal.copyWith(accountName: d.accountName, owner: d.owner)
                : d)
            .toList(),
        ownerIdFilter: currentState.ownerIdFilter,
        stageFilter: currentState.stageFilter,
      )),
    );
  }

  Future<void> _loadDeals(Emitter<DealsListState> emit) async {
    final result = await getDealsUseCase(
      GetDealsParams(ownerId: _ownerId, stage: _stage?.stage),
    );
    await result.fold(
      (f) async => emit(DealsListError(f.message)),
      (deals) async {
        final enriched = await _enrichDeals(deals);
        emit(
          DealsListLoaded(deals: enriched, ownerIdFilter: _ownerId, stageFilter: _stage?.stage),
        );
      },
    );
  }

  /// The `/deals` endpoints only return `account_id`/`owner_id` — resolve
  /// display names client-side so the table/kanban don't show blanks.
  Future<List<Deal>> _enrichDeals(List<Deal> deals) async {
    final accountsResult = await getAccountsUseCase(const GetAccountsParams(limit: 1000));
    final usersResult = await getUsersUseCase();
    final accountNames = <String, String>{};
    accountsResult.fold((_) {}, (page) {
      for (final a in page.items) {
        accountNames[a.id] = a.companyName;
      }
    });
    final ownerNames = <int, String>{};
    usersResult.fold((_) {}, (users) {
      for (final u in users) {
        ownerNames[u.id] = u.displayName;
      }
    });
    return deals
        .map((d) => d.copyWith(
              accountName: accountNames[d.accountId] ?? d.accountName,
              owner: d.ownerId != null ? (ownerNames[d.ownerId] ?? d.owner) : d.owner,
            ))
        .toList();
  }
}

/// Distinguishes "no stage filter set" from "filter explicitly holds a
/// stage value" without needing a sentinel enum member.
class DealStageFilterHolder {
  final DealStage stage;
  const DealStageFilterHolder(this.stage);
}
