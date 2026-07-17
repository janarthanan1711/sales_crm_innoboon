import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

abstract class AccountDetailState extends Equatable {
  const AccountDetailState();
  @override
  List<Object?> get props => [];
}

class AccountDetailInitial extends AccountDetailState {
  const AccountDetailInitial();
}

class AccountDetailLoading extends AccountDetailState {
  const AccountDetailLoading();
}

class AccountDetailLoaded extends AccountDetailState {
  final Account account;
  const AccountDetailLoaded(this.account);
  @override
  List<Object?> get props => [account];
}

class AccountDetailError extends AccountDetailState {
  final String message;
  const AccountDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
