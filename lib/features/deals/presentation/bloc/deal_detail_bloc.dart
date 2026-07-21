import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../accounts/domain/usecases/get_account_by_id_usecase.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/usecases/get_deal_by_id_usecase.dart';
import '../../domain/usecases/get_deal_stage_history_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import 'deal_detail_event.dart';
import 'deal_detail_state.dart';
export 'deal_detail_event.dart';
export 'deal_detail_state.dart';

class DealDetailBloc extends Bloc<DealDetailEvent, DealDetailState> {
  final GetDealByIdUseCase getDealByIdUseCase;
  final UpdateDealStageUseCase updateDealStageUseCase;
  final GetDealStageHistoryUseCase getDealStageHistoryUseCase;
  final GetAccountByIdUseCase getAccountByIdUseCase;
  final GetUsersUseCase getUsersUseCase;

  DealDetailBloc({
    required this.getDealByIdUseCase,
    required this.updateDealStageUseCase,
    required this.getDealStageHistoryUseCase,
    required this.getAccountByIdUseCase,
    required this.getUsersUseCase,
  }) : super(const DealDetailInitial()) {
    on<DealDetailLoadRequested>(_onLoadRequested);
    on<DealDetailStageUpdateRequested>(_onStageUpdateRequested);
  }

  Future<void> _onLoadRequested(
    DealDetailLoadRequested event,
    Emitter<DealDetailState> emit,
  ) async {
    emit(const DealDetailLoading());
    final result = await getDealByIdUseCase(event.id);
    await result.fold(
      (f) async => emit(DealDetailError(f.message)),
      (deal) async {
        final enriched = await _enrichDeal(deal);
        final historyResult = await getDealStageHistoryUseCase(event.id);
        final history = historyResult.fold((_) => const [], (h) => h);
        emit(DealDetailLoaded(enriched, stageHistory: history.cast()));
      },
    );
  }

  Future<void> _onStageUpdateRequested(
    DealDetailStageUpdateRequested event,
    Emitter<DealDetailState> emit,
  ) async {
    emit(const DealDetailLoading());
    final result = await updateDealStageUseCase(
      UpdateDealStageParams(id: event.id, stage: event.stage, note: event.note),
    );
    await result.fold(
      (f) async => emit(DealDetailError(f.message)),
      (deal) async {
        final enriched = await _enrichDeal(deal);
        final historyResult = await getDealStageHistoryUseCase(event.id);
        final history = historyResult.fold((_) => const [], (h) => h);
        emit(DealDetailLoaded(enriched, stageHistory: history.cast()));
      },
    );
  }

  /// The `/deals` endpoints only return `account_id`/`owner_id` — resolve
  /// display names client-side so the page doesn't show blanks.
  Future<Deal> _enrichDeal(Deal deal) async {
    final accountResult = await getAccountByIdUseCase(deal.accountId);
    final usersResult = await getUsersUseCase();
    final accountName = accountResult.fold((_) => deal.accountName, (a) => a.companyName);
    var ownerName = deal.owner;
    usersResult.fold((_) {}, (users) {
      if (deal.ownerId == null) return;
      final match = users.where((u) => u.id == deal.ownerId);
      if (match.isNotEmpty) ownerName = match.first.displayName;
    });
    return deal.copyWith(accountName: accountName, owner: ownerName);
  }
}
