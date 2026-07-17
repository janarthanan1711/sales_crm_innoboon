import 'package:equatable/equatable.dart';

class RevenuePoint extends Equatable {
  final DateTime date;
  final double amount;

  const RevenuePoint({required this.date, required this.amount});

  @override
  List<Object?> get props => [date, amount];
}

class FunnelStage extends Equatable {
  final String stageName;
  final int count;
  final double value;

  const FunnelStage({required this.stageName, required this.count, required this.value});

  @override
  List<Object?> get props => [stageName, count, value];
}

class SalesRepPerformance extends Equatable {
  final String repName;
  final int dealsClosed;
  final double revenueGenerated;
  final double winRate;

  const SalesRepPerformance({
    required this.repName,
    required this.dealsClosed,
    required this.revenueGenerated,
    required this.winRate,
  });

  @override
  List<Object?> get props => [repName, dealsClosed, revenueGenerated, winRate];
}

class SalesMetrics extends Equatable {
  final List<RevenuePoint> revenueHistory;
  final List<RevenuePoint> targetHistory;
  final List<FunnelStage> funnel;
  final double overallWinRate;
  final List<SalesRepPerformance> leaderboard;

  const SalesMetrics({
    required this.revenueHistory,
    required this.targetHistory,
    required this.funnel,
    required this.overallWinRate,
    required this.leaderboard,
  });

  @override
  List<Object?> get props => [revenueHistory, targetHistory, funnel, overallWinRate, leaderboard];
}
