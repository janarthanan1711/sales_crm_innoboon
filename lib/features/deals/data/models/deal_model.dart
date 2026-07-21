import '../../domain/entities/deal.dart';

/// Deal model with JSON serialization — maps to the backend's `DealRead`
/// shape (see `POST/GET/PATCH /deals`). The API has no `account_name`,
/// `contact_*`, `tier`, or `description` fields — those stay on the
/// [Deal] entity for UI convenience but are populated by the caller (e.g.
/// from the account/user already in context), not from this JSON.
class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.name,
    required super.accountId,
    super.accountName = '',
    super.contactId,
    super.contactName,
    required super.value,
    required super.currency,
    required super.stage,
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
      name: json['deal_name'] as String,
      accountId: '${json['account_id']}',
      value: (json['value'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      stage: dealStageFromWire(json['stage'] as String),
      expectedCloseDate: json['expected_close_date'] != null
          ? DateTime.tryParse(json['expected_close_date'] as String)
          : null,
      ownerId: json['owner_id'] as int?,
      owner: json['owner_id'] != null ? 'Owner ${json['owner_id']}' : 'Unassigned',
      coldReason: json['cold_reason'] as String?,
      // Not in the API — best-effort placeholder so existing sort-by-date
      // UI doesn't crash; real chronology comes from `expectedCloseDate`
      // or the stage-history endpoint, not this field, for API-sourced deals.
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
    required DealStage stage,
    required int? ownerId,
  }) {
    return {
      'deal_name': dealName,
      'account_id': int.parse(accountId),
      'value': value,
      'currency': currency,
      if (expectedCloseDate != null)
        'expected_close_date': _formatDate(expectedCloseDate),
      'stage': stage.wireValue,
      if (ownerId != null) 'owner_id': ownerId,
    };
  }

  /// Request body for `PATCH /deals/{id}` (any subset of fields, plus the
  /// write-only `note` recorded on the resulting stage-history row).
  static Map<String, dynamic> toUpdateJson({
    String? dealName,
    double? value,
    String? currency,
    DateTime? expectedCloseDate,
    DealStage? stage,
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
      if (stage != null) 'stage': stage.wireValue,
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
