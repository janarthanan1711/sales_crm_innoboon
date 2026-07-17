import '../../domain/entities/sales_metrics.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsMockDataSource implements AnalyticsRemoteDataSource {
  @override
  Future<SalesMetrics> getSalesMetrics({String period = 'Monthly'}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    
    // Generate 6 months of history
    final revenueHistory = List.generate(6, (i) {
      return RevenuePoint(
        date: DateTime(now.year, now.month - (5 - i), 1),
        amount: 500000.0 + (i * 200000.0) + (i % 2 == 0 ? 100000.0 : -50000.0),
      );
    });

    final targetHistory = List.generate(6, (i) {
      return RevenuePoint(
        date: DateTime(now.year, now.month - (5 - i), 1),
        amount: 600000.0 + (i * 180000.0),
      );
    });

    return SalesMetrics(
      revenueHistory: revenueHistory,
      targetHistory: targetHistory,
      overallWinRate: 0.68,
      funnel: const [
        FunnelStage(stageName: 'Leads', count: 450, value: 0),
        FunnelStage(stageName: 'Qualified', count: 180, value: 45000000),
        FunnelStage(stageName: 'Proposals', count: 85, value: 21000000),
        FunnelStage(stageName: 'Closed Won', count: 58, value: 12500000),
      ],
      leaderboard: const [
        SalesRepPerformance(repName: 'Sarah Jenkins', dealsClosed: 24, revenueGenerated: 6200000, winRate: 0.75),
        SalesRepPerformance(repName: 'M. Chen', dealsClosed: 18, revenueGenerated: 4100000, winRate: 0.62),
        SalesRepPerformance(repName: 'P. Kumar', dealsClosed: 16, revenueGenerated: 2200000, winRate: 0.58),
      ],
    );
  }
}
