import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_contact.dart';

/// Maps the backend's `DealRead` shape (see `POST/GET/PATCH /deals`). The API
/// carries `stage_id` (int, dynamic — see `/deal-stages`) and `contacts`
/// (objects with an id + resolved name). It has no
/// `account_name`/`owner`/`tier`-name/`stage_name` — those are resolved
/// client-side by the caller, not from this JSON.
class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.name,
    required super.accountId,
    super.accountName = '',
    super.contacts,
    super.contactName,
    required super.value,
    required super.currency,
    required super.stageId,
    super.stageName,
    super.stageIsCold,
    super.expectedCloseDate,
    super.ownerId,
    required super.owner,
    super.coldReason,
    super.tier = '',
    super.description = '',
    super.paymentStatus = 'Pending',
    required super.createdAt,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: '${json['id']}',
      name: json['deal_name'] as String? ?? '',
      accountId: '${json['account_id']}',
      contacts: _parseContacts(json),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      stageId: json['stage_id'] as int? ?? 0,
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.tryParse(json['expected_close_date'] as String)
          : null,
      ownerId: json['owner_id'] as int?,
      owner: json['owner_id'] != null
          ? 'Owner ${json['owner_id']}'
          : 'Unassigned',
      coldReason: json['cold_reason'] as String?,
      tier: json['tier'] as String? ?? '',
      // Not in the API — placeholder so sort-by-date UI doesn't crash.
      createdAt: DateTime.now(),
    );
  }

  /// Reads the `contacts` array (`[{id, name}]`). Falls back to a bare
  /// `contact_ids` list — older responses, and `PATCH` echoes that may still
  /// carry ids only — yielding name-less entries the UI renders as "Contact N".
  static List<DealContact> _parseContacts(Map<String, dynamic> json) {
    final raw = json['contacts'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DealContact.fromJson)
          .toList();
    }
    final ids = json['contact_ids'];
    if (ids is List) {
      return ids
          .whereType<int>()
          .map((id) => DealContact(id: id, name: 'Contact $id'))
          .toList();
    }
    return const [];
  }

  /// Request body for `POST /deals`.
  static Map<String, dynamic> toCreateJson({
    required String dealName,
    required String accountId,
    required double value,
    required String currency,
    required DateTime? expectedCloseDate,
    required int stageId,
    List<int>? contactIds,
    String? tier,
    String? coldReason,
    required int? ownerId,
  }) {
    return {
      'deal_name': dealName,
      'account_id': int.parse(accountId),
      'value': value,
      'currency': currency,
      if (expectedCloseDate != null)
        'expected_close_date': _formatDate(expectedCloseDate),
      'stage_id': stageId,
      if (contactIds != null && contactIds.isNotEmpty)
        'contact_ids': contactIds,
      if (tier != null && tier.isNotEmpty) 'tier': tier,
      if (coldReason != null && coldReason.isNotEmpty)
        'cold_reason': coldReason,
      'owner_id': ?ownerId,
    };
  }

  /// Request body for `PATCH /deals/{id}` (any subset, plus the write-only
  /// `note` recorded on the resulting stage-history row when `stage_id`
  /// changes). `contact_ids`, if supplied, fully replaces the deal's links.
  static Map<String, dynamic> toUpdateJson({
    String? dealName,
    double? value,
    String? currency,
    DateTime? expectedCloseDate,
    int? stageId,
    List<int>? contactIds,
    String? coldReason,
    String? tier,
    int? ownerId,
    String? note,
  }) {
    return {
      'deal_name': ?dealName,
      'value': ?value,
      'currency': ?currency,
      if (expectedCloseDate != null)
        'expected_close_date': _formatDate(expectedCloseDate),
      'stage_id': ?stageId,
      'contact_ids': ?contactIds,
      'cold_reason': ?coldReason,
      'owner_id': ?ownerId,
      'tier': ?tier,
      'note': ?note,
    };
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
