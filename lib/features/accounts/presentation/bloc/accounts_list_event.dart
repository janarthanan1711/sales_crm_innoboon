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
  final String? owner;
  const AccountsListFilterChanged({this.industry, this.tier, this.owner});
  @override
  List<Object?> get props => [industry, tier, owner];
}
