import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../domain/usecases/get_account_by_id_usecase.dart';
import '../../domain/usecases/get_account_contacts_usecase.dart';
import '../../domain/usecases/get_account_deals_usecase.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';
export 'account_detail_event.dart';
export 'account_detail_state.dart';

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  final GetAccountByIdUseCase getAccountByIdUseCase;
  final GetAccountContactsUseCase getAccountContactsUseCase;
  final GetAccountDealsUseCase getAccountDealsUseCase;

  AccountDetailBloc({
    required this.getAccountByIdUseCase,
    required this.getAccountContactsUseCase,
    required this.getAccountDealsUseCase,
  }) : super(const AccountDetailInitial()) {
    on<AccountDetailLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    AccountDetailLoadRequested event,
    Emitter<AccountDetailState> emit,
  ) async {
    emit(const AccountDetailLoading());
    final accountResult = await getAccountByIdUseCase(event.id);
    await accountResult.fold(
      (f) async => emit(AccountDetailError(f.message)),
      (account) async {
        final contactsFuture = getAccountContactsUseCase(event.id);
        final dealsFuture = getAccountDealsUseCase(event.id);
        final contactsResult = await contactsFuture;
        final dealsResult = await dealsFuture;
        final contacts = contactsResult.fold((_) => <Contact>[], (c) => c);
        final deals = dealsResult.fold((_) => <Deal>[], (d) => d);
        emit(AccountDetailLoaded(account, contacts: contacts, deals: deals));
      },
    );
  }
}
