import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/sales_metrics.dart';
import '../bloc/analytics_bloc.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
      child: const _AnalyticsView(),
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView();

  @override
  Widget build(BuildContext context) {
    final padding = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xxl),
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AnalyticsError) {
                  return ErrorState(
                    message: state.message, 
                    onRetry: () => context.read<AnalyticsBloc>().add(const AnalyticsLoadRequested())
                  );
                }
                if (state is AnalyticsLoaded) {
                  return _buildDashboardContent(context, state.metrics);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance Analytics', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'Track your team\'s sales metrics and conversion rates',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Last 6 Months', style: AppTextStyles.labelMedium),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance Analytics', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(
              'Track your team\'s sales metrics and conversion rates',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Row(
            children: [
              Text('Last 6 Months', style: AppTextStyles.labelMedium),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, SalesMetrics metrics) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RevenueChartCard(metrics: metrics),
          const SizedBox(height: AppSpacing.xl),
          _WinRateCard(winRate: metrics.overallWinRate),
          const SizedBox(height: AppSpacing.xl),
          _FunnelChartCard(funnel: metrics.funnel),
          const SizedBox(height: AppSpacing.xl),
          _LeaderboardCard(leaderboard: metrics.leaderboard),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Row: Revenue Chart & Win Rate
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _RevenueChartCard(metrics: metrics),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 3,
              child: _WinRateCard(winRate: metrics.overallWinRate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        // Bottom Row: Funnel & Leaderboard
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _FunnelChartCard(funnel: metrics.funnel),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 6,
              child: _LeaderboardCard(leaderboard: metrics.leaderboard),
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({required this.metrics});
  final SalesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Revenue Overview vs Target',
      child: SizedBox(
        height: 300,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, left: 8, top: 24, bottom: 8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 200000,
                getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [5, 5]),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < metrics.revenueHistory.length) {
                        final date = metrics.revenueHistory[value.toInt()].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(DateFormat('MMM').format(date), style: AppTextStyles.caption),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 500000,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${(value / 100000).toStringAsFixed(0)}L',
                        style: AppTextStyles.caption,
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: metrics.revenueHistory.length.toDouble() - 1,
              minY: 0,
              maxY: 2000000,
              lineBarsData: [
                // Target Line
                LineChartBarData(
                  spots: metrics.targetHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                  isCurved: true,
                  color: AppColors.textMuted,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  dashArray: [5, 5],
                ),
                // Revenue Line
                LineChartBarData(
                  spots: metrics.revenueHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WinRateCard extends StatelessWidget {
  const _WinRateCard({required this.winRate});
  final double winRate;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Overall Win Rate',
      child: SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          color: AppColors.success,
                          value: winRate * 100,
                          title: '',
                          radius: 20,
                        ),
                        PieChartSectionData(
                          color: AppColors.border,
                          value: (1 - winRate) * 100,
                          title: '',
                          radius: 20,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(winRate * 100).toStringAsFixed(1)}%', style: AppTextStyles.h1),
                      Text('Won', style: AppTextStyles.caption),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_upward, size: 16, color: AppColors.success),
                const SizedBox(width: 4),
                Text('+2.4% from last month', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FunnelChartCard extends StatelessWidget {
  const _FunnelChartCard({required this.funnel});
  final List<FunnelStage> funnel;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Conversion Funnel',
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            ...funnel.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              final maxCount = funnel.first.count.toDouble();
              final widthFactor = stage.count / maxCount;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(stage.stageName, style: AppTextStyles.labelMedium)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 24,
                          width: MediaQuery.of(context).size.width * 0.2 * widthFactor,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 1.0 - (index * 0.2)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 60, 
                      child: Text('${stage.count}', style: AppTextStyles.labelLarge, textAlign: TextAlign.right),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.leaderboard});
  final List<SalesRepPerformance> leaderboard;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Top Performers',
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('REP NAME', style: AppTextStyles.tableHeader)),
                  Expanded(flex: 2, child: Text('DEALS WON', style: AppTextStyles.tableHeader)),
                  Expanded(flex: 3, child: Text('REVENUE', style: AppTextStyles.tableHeader)),
                  Expanded(flex: 2, child: Text('WIN RATE', style: AppTextStyles.tableHeader)),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: leaderboard.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rep = leaderboard[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3, 
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primaryLight,
                                child: Text(rep.repName[0], style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(rep.repName, style: AppTextStyles.labelLarge),
                            ],
                          )
                        ),
                        Expanded(flex: 2, child: Text('${rep.dealsClosed}', style: AppTextStyles.tableCell)),
                        Expanded(flex: 3, child: Text(CurrencyFormatter.formatINR(rep.revenueGenerated), style: AppTextStyles.labelMedium.copyWith(color: AppColors.success))),
                        Expanded(flex: 2, child: Text('${(rep.winRate * 100).toStringAsFixed(1)}%', style: AppTextStyles.tableCell)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
