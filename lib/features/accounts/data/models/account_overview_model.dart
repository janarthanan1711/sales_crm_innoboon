import '../../../contacts/data/models/contact_model.dart';
import '../../../deals/data/models/deal_model.dart';
import '../../domain/entities/account_overview.dart';
import 'account_model.dart';

AccountOverview accountOverviewFromJson(Map<String, dynamic> json) {
  final keyContacts = (json['key_contacts'] as List<dynamic>? ?? const [])
      .map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
      .toList();
  final activeDeals = (json['active_deals'] as List<dynamic>? ?? const [])
      .map((e) => DealModel.fromJson(e as Map<String, dynamic>))
      .toList();
  return AccountOverview(
    // The overview response embeds all AccountRead fields at the top level,
    // so the same model parses the account header (minus contact/deal counts,
    // which the detail page derives from the loaded lists).
    account: AccountModel.fromJson(json),
    openDealValue: (json['open_deal_value'] as num?)?.toDouble() ?? 0,
    keyContacts: keyContacts,
    activeDeals: activeDeals,
    totalArr: (json['total_arr'] as num?)?.toDouble(),
    lastActivity: json['last_activity'] as String?,
    nextStep: json['next_step'] as String?,
  );
}
