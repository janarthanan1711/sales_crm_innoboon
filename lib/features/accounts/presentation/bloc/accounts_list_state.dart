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
  final int total;
  final int limit;
  final int offset;
  final String? search;
  final String? industryFilter;
  final String? tierFilter;
  final int? ownerFilter;

  const AccountsListLoaded({
    required this.accounts,
    required this.total,
    required this.limit,
    required this.offset,
    this.search,
    this.industryFilter,
    this.tierFilter,
    this.ownerFilter,
  });

  int get pageStart => total == 0 ? 0 : offset + 1;
  int get pageEnd => (offset + accounts.length);
  bool get hasPrev => offset > 0;
  bool get hasNext => offset + limit < total;

  @override
  List<Object?> get props => [
    accounts,
    total,
    limit,
    offset,
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
