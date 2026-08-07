import '../../domain/entities/dashboard_data.dart';

DashboardData dashboardFromJson(Map<String, dynamic> json) {
  return DashboardData(
    summary: _summaryFromJson(
      json['summary'] as Map<String, dynamic>? ?? const {},
    ),
    funnel: _listOf(json['funnel'], 'stages', _funnelStageFromJson),
    dealDistribution: _listOf(
      json['deal_distribution'],
      'entries',
      _distributionFromJson,
    ),
    leaderboard: _listOf(json['leaderboard'], 'entries', _leaderboardFromJson),
    dropOffReasons: _listOf(
      json['drop_off_reasons'],
      'entries',
      _dropOffFromJson,
    ),
    conversionTrend: _listOf(
      json['conversion_trend'],
      'entries',
      _conversionFromJson,
    ),
    activityFeed: _listOf(json['activity_feed'], 'entries', _activityFromJson),
  );
}

/// Each section is an object wrapping a list under [key]; tolerate a missing
/// section (empty dashboard is a valid state).
List<T> _listOf<T>(
  dynamic section,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (section is! Map<String, dynamic>) return const [];
  final raw = section[key] as List<dynamic>? ?? const [];
  return raw
      .map((e) => fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

DashboardStat _statFromJson(Map<String, dynamic>? json) {
  if (json == null) return const DashboardStat(value: 0);
  return DashboardStat(
    value: (json['value'] as num?)?.toInt() ?? 0,
    changePct: (json['change_pct'] as num?)?.toDouble(),
  );
}

DashboardSummary _summaryFromJson(Map<String, dynamic> json) {
  return DashboardSummary(
    leadsGenerated: _statFromJson(
      json['leads_generated'] as Map<String, dynamic>?,
    ),
    qualifiedLeads: _statFromJson(
      json['qualified_leads'] as Map<String, dynamic>?,
    ),
    dealsInPipeline: _statFromJson(
      json['deals_in_pipeline'] as Map<String, dynamic>?,
    ),
    dealsClosed: _statFromJson(json['deals_closed'] as Map<String, dynamic>?),
    // Left null (tile hidden) rather than defaulted to zero when the API
    // build in use doesn't return the section yet.
    numAccounts: json['num_accounts'] is Map<String, dynamic>
        ? _statFromJson(json['num_accounts'] as Map<String, dynamic>)
        : null,
  );
}

FunnelStage _funnelStageFromJson(Map<String, dynamic> json) {
  return FunnelStage(
    stageName: json['stage_name'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

DealDistributionEntry _distributionFromJson(Map<String, dynamic> json) {
  return DealDistributionEntry(
    tier: json['tier'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
    totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
  );
}

LeaderboardEntry _leaderboardFromJson(Map<String, dynamic> json) {
  return LeaderboardEntry(
    ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
    ownerName: json['owner_name'] as String? ?? 'Unknown',
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    dealsClosed: (json['deals_closed'] as num?)?.toInt() ?? 0,
    // `owner_avatar_url` is the documented field; `avatar_url` is accepted as
    // an alias so either server naming works without a client release.
    avatarUrl:
        json['owner_avatar_url'] as String? ?? json['avatar_url'] as String?,
  );
}

DropOffReason _dropOffFromJson(Map<String, dynamic> json) {
  return DropOffReason(
    reason: json['reason'] as String? ?? 'Unknown',
    stageLost: json['stage_lost'] as String? ?? 'Unknown',
    count: (json['count'] as num?)?.toInt() ?? 0,
    lostValue: (json['lost_value'] as num?)?.toDouble() ?? 0,
    changePct: (json['change_pct'] as num?)?.toDouble(),
  );
}

ConversionTrendEntry _conversionFromJson(Map<String, dynamic> json) {
  return ConversionTrendEntry(
    period:
        DateTime.tryParse(json['period'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    stageName: json['stage_name'] as String? ?? '',
    count: (json['count'] as num?)?.toInt() ?? 0,
  );
}

DashboardActivity _activityFromJson(Map<String, dynamic> json) {
  return DashboardActivity(
    entityType: json['entity_type'] as String? ?? '',
    entityId: (json['entity_id'] as num?)?.toInt() ?? 0,
    type: json['type'] as String? ?? '',
    note: json['note'] as String?,
    createdByName: json['created_by_name'] as String?,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
