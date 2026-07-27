import 'package:equatable/equatable.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../deals/domain/entities/deal.dart';
import 'account.dart';

/// Everything the Account Detail → Overview tab needs, from the single
/// `GET /accounts/{id}/overview` call.
///
/// [totalArr], [lastActivity] and [nextStep] are always `null` today — the
/// backend has no ARR / account-activity / follow-up model yet, and returns
/// `null` (explicitly "not available", NOT zero), so the UI must render them
/// as empty/placeholder state rather than "0".
class AccountOverview extends Equatable {
  final Account account;

  /// Sum of `value` across every deal not in closed_won/closed_lost/cold.
  final double openDealValue;

  /// The account's full contact list (there's no curated "key contact" flag).
  final List<Contact> keyContacts;

  /// Every deal not in a closed/cold stage, full DealRead shape.
  final List<Deal> activeDeals;

  final double? totalArr;
  final String? lastActivity;
  final String? nextStep;

  const AccountOverview({
    required this.account,
    this.openDealValue = 0,
    this.keyContacts = const [],
    this.activeDeals = const [],
    this.totalArr,
    this.lastActivity,
    this.nextStep,
  });

  @override
  List<Object?> get props => [
    account,
    openDealValue,
    keyContacts,
    activeDeals,
    totalArr,
    lastActivity,
    nextStep,
  ];
}
