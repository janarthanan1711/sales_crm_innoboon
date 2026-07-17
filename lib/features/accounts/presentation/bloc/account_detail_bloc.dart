import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_account_by_id_usecase.dart';
import 'account_detail_event.dart';
import 'account_detail_state.dart';
export 'account_detail_event.dart';
export 'account_detail_state.dart';

class AccountDetailBloc extends Bloc<AccountDetailEvent, AccountDetailState> {
  final GetAccountByIdUseCase getAccountByIdUseCase;
  AccountDetailBloc({required this.getAccountByIdUseCase})
    : super(const AccountDetailInitial()) {
    on<AccountDetailLoadRequested>((event, emit) async {
      emit(const AccountDetailLoading());
      final result = await getAccountByIdUseCase(event.id);
      result.fold(
        (f) => emit(AccountDetailError(f.message)),
        (a) => emit(AccountDetailLoaded(a)),
      );
    });
  }
}
