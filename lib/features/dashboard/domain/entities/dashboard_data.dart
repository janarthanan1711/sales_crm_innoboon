import 'package:equatable/equatable.dart';

/// A single stat tile value with an optional period-over-period change.
/// [changePct] is null when there's no prior period to compare against, or
/// (for a current snapshot like deals-in-pipeline) when no trend applies.
class DashboardStat extends Equatable {
  final int value;
  final double? changePct;

  const DashboardStat({required this.value, this.changePct});

  @override
  List<Object?> get props => [value, changePct];
}

/// The top-of-page stat tiles, scoped by the selected period.
class DashboardSummary extends Equatable {
  final DashboardStat leadsGenerated;
  final DashboardStat qualifiedLeads;
  final DashboardStat dealsInPipeline;
  final DashboardStat dealsClosed;

  /// Accounts created in the period (`summary.num_accounts`).
  ///
  /// Null — not a zero stat — when the API omits the section, so the tile can
  /// be left out entirely rather than reporting a fabricated 0 against a
  /// build that doesn't compute it yet.
  final DashboardStat? numAccounts;

  const DashboardSummary({
    required this.leadsGenerated,
    required this.qualifiedLeads,
    required this.dealsInPipeline,
    required this.dealsClosed,
    this.numAccounts,
  });

  @override
  List<Object?> get props => [
    leadsGenerated,
    qualifiedLeads,
    dealsInPipeline,
    dealsClosed,
    numAccounts,
  ];
}

/// One row of the Pipeline Funnel, ordered server-side by stage sort order.
class FunnelStage extends Equatable {
  final String stageName;
  final int count;

  const FunnelStage({required this.stageName, required this.count});

  @override
  List<Object?> get props => [stageName, count];
}

/// One slice of the Deal Distribution donut (grouped by tier).
class DealDistributionEntry extends Equatable {
  final String tier;
  final int count;
  final double totalValue;

  const DealDistributionEntry({
    required this.tier,
    required this.count,
    required this.totalValue,
  });

  @override
  List<Object?> get props => [tier, count, totalValue];
}

/// One rep on the Sales Leaderboard, ranked by won-deal revenue.
class LeaderboardEntry extends Equatable {
  final int ownerId;
  final String ownerName;
  final double revenue;
  final int dealsClosed;

  /// The rep's avatar path (`/media/avatars/12.png`) when known, so the row
  /// shows their photo instead of initials. Comes from the payload's
  /// `owner_avatar_url` if present, otherwise filled in from `GET /users` —
  /// see `DashboardBloc`. Null means "fall back to initials".
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.ownerId,
    required this.ownerName,
    required this.revenue,
    required this.dealsClosed,
    this.avatarUrl,
  });

  LeaderboardEntry copyWith({String? avatarUrl}) => LeaderboardEntry(
    ownerId: ownerId,
    ownerName: ownerName,
    revenue: revenue,
    dealsClosed: dealsClosed,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );

  @override
  List<Object?> get props => [
    ownerId,
    ownerName,
    revenue,
    dealsClosed,
    avatarUrl,
  ];
}

/// One row of the Drop-off Reasons (lost/cold deals) table.
class DropOffReason extends Equatable {
  final String reason;
  final String stageLost;
  final int count;
  final double lostValue;
  final double? changePct;

  const DropOffReason({
    required this.reason,
    required this.stageLost,
    required this.count,
    required this.lostValue,
    this.changePct,
  });

  @override
  List<Object?> get props => [reason, stageLost, count, lostValue, changePct];
}

/// One point of the Conversion Trend series (raw per-stage transition count
/// bucketed by period). [period] is the bucket's start date.
class ConversionTrendEntry extends Equatable {
  final DateTime period;
  final String stageName;
  final int count;

  const ConversionTrendEntry({
    required this.period,
    required this.stageName,
    required this.count,
  });

  @override
  List<Object?> get props => [period, stageName, count];
}

/// One item of the merged Activity Feed across deal/lead/account logs.
class DashboardActivity extends Equatable {
  final String entityType; // deal | lead | account
  final int entityId;
  final String type; // note | meeting | call | comment | follow_up
  final String? note;
  final String? createdByName;
  final DateTime createdAt;

  const DashboardActivity({
    required this.entityType,
    required this.entityId,
    required this.type,
    this.note,
    this.createdByName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    entityType,
    entityId,
    type,
    note,
    createdByName,
    createdAt,
  ];
}

/// The full `GET /dashboard` payload — one call powers the whole page.
class DashboardData extends Equatable {
  final DashboardSummary summary;
  final List<FunnelStage> funnel;
  final List<DealDistributionEntry> dealDistribution;
  final List<LeaderboardEntry> leaderboard;
  final List<DropOffReason> dropOffReasons;
  final List<ConversionTrendEntry> conversionTrend;
  final List<DashboardActivity> activityFeed;

  const DashboardData({
    required this.summary,
    this.funnel = const [],
    this.dealDistribution = const [],
    this.leaderboard = const [],
    this.dropOffReasons = const [],
    this.conversionTrend = const [],
    this.activityFeed = const [],
  });

  /// Replaces the leaderboard, preserving every other section — used to graft
  /// avatar URLs on after the payload has been parsed.
  DashboardData withLeaderboard(List<LeaderboardEntry> entries) =>
      DashboardData(
        summary: summary,
        funnel: funnel,
        dealDistribution: dealDistribution,
        leaderboard: entries,
        dropOffReasons: dropOffReasons,
        conversionTrend: conversionTrend,
        activityFeed: activityFeed,
      );

  @override
  List<Object?> get props => [
    summary,
    funnel,
    dealDistribution,
    leaderboard,
    dropOffReasons,
    conversionTrend,
    activityFeed,
  ];
}
