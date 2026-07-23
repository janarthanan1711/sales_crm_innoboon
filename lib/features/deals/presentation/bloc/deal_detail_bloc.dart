import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../accounts/domain/usecases/get_account_by_id_usecase.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/usecases/get_deal_by_id_usecase.dart';
import '../../domain/usecases/get_deal_stages_usecase.dart';
import '../../domain/usecases/get_deal_stage_history_usecase.dart';
import '../../domain/usecases/update_deal_stage_usecase.dart';
import 'deal_detail_event.dart';
import 'deal_detail_state.dart';
export 'deal_detail_event.dart';
export 'deal_detail_state.dart';

class DealDetailBloc extends Bloc<DealDetailEvent, DealDetailState> {
  final GetDealByIdUseCase getDealByIdUseCase;
  final GetDealStagesUseCase getDealStagesUseCase;
  final UpdateDealStageUseCase updateDealStageUseCase;
  final GetDealStageHistoryUseCase getDealStageHistoryUseCase;
  final GetAccountByIdUseCase getAccountByIdUseCase;
  final GetUsersUseCase getUsersUseCase;

  List<DealStageDef> _stages = const [];

  DealDetailBloc({
    required this.getDealByIdUseCase,
    required this.getDealStagesUseCase,
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
    await _loadAndEmit(event.id, emit);
  }

  Future<void> _onStageUpdateRequested(
    DealDetailStageUpdateRequested event,
    Emitter<DealDetailState> emit,
  ) async {
    emit(const DealDetailLoading());
    final result = await updateDealStageUseCase(
      UpdateDealStageParams(
        id: event.id,
        stageId: event.stageId,
        note: event.note,
        coldReason: event.coldReason,
      ),
    );
    await result.fold(
      (f) async => emit(DealDetailError(f.message)),
      (_) async => _loadAndEmit(event.id, emit),
    );
  }

  Future<void> _loadAndEmit(String id, Emitter<DealDetailState> emit) async {
    if (_stages.isEmpty) {
      final stagesResult = await getDealStagesUseCase();
      stagesResult.fold((_) {}, (s) => _stages = s);
    }
    final result = await getDealByIdUseCase(id);
    await result.fold(
      (f) async => emit(DealDetailError(f.message)),
      (deal) async {
        final enriched = await _enrichDeal(deal);
        final historyResult = await getDealStageHistoryUseCase(id);
        final history = historyResult.fold(
          (_) => <DealStageHistoryEntry>[],
          (h) => h,
        );
        emit(DealDetailLoaded(enriched, stages: _stages, stageHistory: history));
      },
    );
  }

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
    final stageMatches = _stages.where((s) => s.id == deal.stageId);
    final stage = stageMatches.isEmpty ? null : stageMatches.first;
    return deal.copyWith(
      accountName: accountName,
      owner: ownerName,
      stageName: stage?.name ?? deal.stageName,
      stageIsCold: stage?.isCold ?? deal.stageIsCold,
    );
  }
}
