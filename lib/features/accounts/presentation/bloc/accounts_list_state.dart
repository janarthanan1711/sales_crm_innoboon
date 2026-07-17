import 'package:equatable/equatable.dart';
import '../../domain/entities/account.dart';

abstract class AccountsListState extends Equatable {
  const AccountsListState();
  @override
  List<Object?> get props => [];
}

class AccountsListInitial extends AccountsListState {
  const AccountsListInitial();
}

class AccountsListLoading extends AccountsListState {
  const AccountsListLoading();
}

class AccountsListLoaded extends AccountsListState {
  final List<Account> accounts;
  final String? search;
  final String? industryFilter;
  final String? tierFilter;
  final String? ownerFilter;

  const AccountsListLoaded({
    required this.accounts,
    this.search,
    this.industryFilter,
    this.tierFilter,
    this.ownerFilter,
  });

  @override
  List<Object?> get props => [
    accounts,
    search,
    industryFilter,
    tierFilter,
    ownerFilter,
  ];
}

class AccountsListError extends AccountsListState {
  final String message;
  const AccountsListError(this.message);
  @override
  List<Object?> get props => [message];
}
