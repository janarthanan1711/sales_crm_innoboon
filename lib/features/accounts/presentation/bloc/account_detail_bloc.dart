import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../deals/domain/entities/deal_stage_def.dart';
import '../../../deals/domain/usecases/get_deal_stages_usecase.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/get_account_contacts_usecase.dart';
import '../../domain/usecases/get_account_deals_usecase.dart';
import '../../domain/usecases/get_account_overview_usecase.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';
export 'account_detail_event.dart';
export 'account_detail_state.dart';

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  final GetAccountOverviewUseCase getAccountOverviewUseCase;
  final GetAccountContactsUseCase getAccountContactsUseCase;
  final GetAccountDealsUseCase getAccountDealsUseCase;
  final GetDealStagesUseCase getDealStagesUseCase;
  final GetUsersUseCase getUsersUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;

  AccountDetailBloc({
    required this.getAccountOverviewUseCase,
    required this.getAccountContactsUseCase,
    required this.getAccountDealsUseCase,
    required this.getDealStagesUseCase,
    required this.getUsersUseCase,
    required this.deleteAccountUseCase,
  }) : super(const AccountDetailInitial()) {
    on<AccountDetailLoadRequested>(_onLoadRequested);
    on<AccountDetailDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onDeleteRequested(
    AccountDetailDeleteRequested event,
    Emitter<AccountDetailState> emit,
  ) async {
    emit(const AccountDetailLoading());
    final result = await deleteAccountUseCase(event.id);
    result.fold(
      (failure) => emit(AccountDetailError(failure.message)),
      (_) => emit(const AccountDetailDeleted()),
    );
  }

  Future<void> _onLoadRequested(
    AccountDetailLoadRequested event,
    Emitter<AccountDetailState> emit,
  ) async {
    emit(const AccountDetailLoading());

    // Overview drives the header + open-deal-value; the paginated contacts
    // endpoint drives the Contacts tab (it carries `is_primary`, which the
    // overview's key_contacts also do, but the tab wants the full
    // AccountContactRead list explicitly).
    //
    // The Deals tab uses `/accounts/{id}/deals` rather than the overview's
    // `active_deals`: the latter only carries id/name/stage_id/value, which
    // isn't enough to render a useful row.
    final overviewFuture = getAccountOverviewUseCase(event.id);
    final contactsFuture = getAccountContactsUseCase(event.id);
    final dealsFuture = getAccountDealsUseCase(event.id);
    final stagesFuture = getDealStagesUseCase();
    final usersFuture = getUsersUseCase();

    final overviewResult = await overviewFuture;
    final contactsResult = await contactsFuture;
    final dealsResult = await dealsFuture;
    final stagesResult = await stagesFuture;
    final usersResult = await usersFuture;

    await overviewResult.fold(
      (f) async => emit(AccountDetailError(f.message)),
      (overview) async {
        // Fall back to the overview's key_contacts if the dedicated contacts
        // call failed, so the tab still shows something.
        final contacts = contactsResult.fold(
          (_) => overview.keyContacts,
          (c) => c.isNotEmpty ? c : overview.keyContacts,
        );

        // Same idea for deals: on failure fall back to the overview's slimmer
        // active_deals rather than showing an empty tab.
        final rawDeals = dealsResult.fold(
          (_) => overview.activeDeals,
          (d) => d,
        );

        final stages = stagesResult.fold(
          (_) => const <DealStageDef>[],
          (s) => s,
        );
        final ownerNames = <int, String>{};
        usersResult.fold((_) {}, (users) {
          for (final u in users) {
            ownerNames[u.id] = u.displayName;
          }
        });

        emit(AccountDetailLoaded(
          overview.account,
          contacts: contacts,
          deals: _resolveNames(rawDeals, stages, ownerNames),
          openDealValue: overview.openDealValue,
          totalArr: overview.totalArr,
          lastActivity: overview.lastActivity,
          nextStep: overview.nextStep,
        ));
      },
    );
  }

  /// `DealRead` carries only `stage_id`/`owner_id`, so fill in the display
  /// names client-side (same approach as DealsListBloc).
  List<Deal> _resolveNames(
    List<Deal> deals,
    List<DealStageDef> stages,
    Map<int, String> ownerNames,
  ) {
    return deals.map((d) {
      final matches = stages.where((s) => s.id == d.stageId);
      final stage = matches.isEmpty ? null : matches.first;
      return d.copyWith(
        stageName: stage?.name ?? d.stageName,
        stageIsCold: stage?.isCold ?? d.stageIsCold,
        owner: d.ownerId != null ? (ownerNames[d.ownerId] ?? d.owner) : d.owner,
      );
    }).toList();
  }
}
