import '../../domain/entities/deal.dart';

/// Maps the backend's `DealRead` shape (see `POST/GET/PATCH /deals`). The API
/// carries `stage_id` (int, dynamic — see `/deal-stages`) and `contact_ids`
/// (a list). It has no `account_name`/`owner`/`tier`-name/`stage_name` —
/// those are resolved client-side by the caller, not from this JSON.
class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.name,
    required super.accountId,
    super.accountName = '',
    super.contactIds,
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
      contactIds: (json['contact_ids'] as List<dynamic>? ?? const [])
          .map((e) => e as int)
          .toList(),
      value: (json['value'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      stageId: json['stage_id'] as int? ?? 0,
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.tryParse(json['expected_close_date'] as String)
          : null,
      ownerId: json['owner_id'] as int?,
      owner: json['owner_id'] != null ? 'Owner ${json['owner_id']}' : 'Unassigned',
      coldReason: json['cold_reason'] as String?,
      tier: json['tier'] as String? ?? '',
      // Not in the API — placeholder so sort-by-date UI doesn't crash.
      createdAt: DateTime.now(),
    );
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
      if (contactIds != null && contactIds.isNotEmpty) 'contact_ids': contactIds,
      if (tier != null && tier.isNotEmpty) 'tier': tier,
      if (coldReason != null && coldReason.isNotEmpty) 'cold_reason': coldReason,
      if (ownerId != null) 'owner_id': ownerId,
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
    int? ownerId,
    String? note,
  }) {
    return {
      if (dealName != null) 'deal_name': dealName,
      if (value != null) 'value': value,
      if (currency != null) 'currency': currency,
      if (expectedCloseDate != null)
        'expected_close_date': _formatDate(expectedCloseDate),
      if (stageId != null) 'stage_id': stageId,
      if (contactIds != null) 'contact_ids': contactIds,
      if (coldReason != null) 'cold_reason': coldReason,
      if (ownerId != null) 'owner_id': ownerId,
      if (note != null) 'note': note,
    };
  }

  static String _formatDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
