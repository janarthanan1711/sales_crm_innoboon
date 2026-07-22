import 'package:equatable/equatable.dart';

abstract class AccountsListEvent extends Equatable {
  const AccountsListEvent();
  @override
  List<Object?> get props => [];
}

class AccountsListLoadRequested extends AccountsListEvent {
  const AccountsListLoadRequested();
}

class AccountsListSearchChanged extends AccountsListEvent {
  final String query;
  const AccountsListSearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class AccountsListFilterChanged extends AccountsListEvent {
  final String? industry;
  final String? tier;
  /// Sentinel: pass `AccountsListFilterChanged.clearOwner` to reset the owner
  /// filter (null means "leave unchanged" so other filters can be set alone).
  final Object? ownerId;

  const AccountsListFilterChanged({this.industry, this.tier, this.ownerId});

  /// Distinguishes "clear the owner filter" from "don't touch it".
  static const Object clearOwner = 'clear-owner';

  @override
  List<Object?> get props => [industry, tier, ownerId];
}

class AccountsListPageChanged extends AccountsListEvent {
  final int offset;
  const AccountsListPageChanged(this.offset);
  @override
  List<Object?> get props => [offset];
}

class AccountsListRowsPerPageChanged extends AccountsListEvent {
  final int limit;
  const AccountsListRowsPerPageChanged(this.limit);
  @override
  List<Object?> get props => [limit];
}
