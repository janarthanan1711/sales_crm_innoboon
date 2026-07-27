import 'package:equatable/equatable.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/domain/entities/deal.dart';
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
  final List<Contact> contacts;
  final List<Deal> deals;
  final double openDealValue;

  /// `null` when the backend has no value yet (ARR / activity / next-step
  /// models don't exist) — render as a placeholder, never as "0".
  final double? totalArr;
  final String? lastActivity;
  final String? nextStep;

  const AccountDetailLoaded(
    this.account, {
    this.contacts = const [],
    this.deals = const [],
    this.openDealValue = 0,
    this.totalArr,
    this.lastActivity,
    this.nextStep,
  });

  @override
  List<Object?> get props => [
    account,
    contacts,
    deals,
    openDealValue,
    totalArr,
    lastActivity,
    nextStep,
  ];
}

class AccountDetailError extends AccountDetailState {
  final String message;
  const AccountDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
