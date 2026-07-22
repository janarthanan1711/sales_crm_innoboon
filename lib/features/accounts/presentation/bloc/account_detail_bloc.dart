import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_account_contacts_usecase.dart';
import '../../domain/usecases/get_account_overview_usecase.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';
export 'account_detail_event.dart';
export 'account_detail_state.dart';

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  final GetAccountOverviewUseCase getAccountOverviewUseCase;
  final GetAccountContactsUseCase getAccountContactsUseCase;

  AccountDetailBloc({
    required this.getAccountOverviewUseCase,
    required this.getAccountContactsUseCase,
  }) : super(const AccountDetailInitial()) {
    on<AccountDetailLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AccountDetailLoadRequested event,
    Emitter<AccountDetailState> emit,
  ) async {
    emit(const AccountDetailLoading());

    // Overview drives the header + Deals tab + open-deal-value; the paginated
    // contacts endpoint drives the Contacts tab (it carries `is_primary`,
    // which the overview's key_contacts also do, but the tab wants the full
    // AccountContactRead list explicitly).
    final overviewFuture = getAccountOverviewUseCase(event.id);
    final contactsFuture = getAccountContactsUseCase(event.id);
    final overviewResult = await overviewFuture;
    final contactsResult = await contactsFuture;

    await overviewResult.fold(
      (f) async => emit(AccountDetailError(f.message)),
      (overview) async {
        // Fall back to the overview's key_contacts if the dedicated contacts
        // call failed, so the tab still shows something.
        final contacts = contactsResult.fold(
          (_) => overview.keyContacts,
          (c) => c.isNotEmpty ? c : overview.keyContacts,
        );
        emit(AccountDetailLoaded(
          overview.account,
          contacts: contacts,
          deals: overview.activeDeals,
          openDealValue: overview.openDealValue,
          totalArr: overview.totalArr,
          lastActivity: overview.lastActivity,
          nextStep: overview.nextStep,
        ));
      },
    );
  }
}
