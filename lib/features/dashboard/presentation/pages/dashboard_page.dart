import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../app/di/injector.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../performance_dashboard/presentation/bloc/analytics_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: AppTextStyles.h1),
            const SizedBox(height: 4),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final name = state is AuthAuthenticated ? state.user.name : 'Sarah Jenkins';
                return Text('Welcome back, $name', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
              },
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Quick stats
            BlocBuilder<AnalyticsBloc, AnalyticsState>(
              builder: (context, state) {
                if (state is AnalyticsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is AnalyticsError) {
                  return Text('Error loading stats: ${state.message}', style: const TextStyle(color: Colors.red));
                }
                if (state is AnalyticsLoaded) {
                  final totalLeads = state.metrics.funnel.firstWhere((f) => f.stageName == 'Leads').count;
                  final activeDeals = state.metrics.funnel.firstWhere((f) => f.stageName == 'Proposals').count;
                  final pipelineValue = state.metrics.funnel.firstWhere((f) => f.stageName == 'Proposals').value;
                  
                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: [
                      _StatCard(title: 'Total Leads', value: '$totalLeads', icon: Icons.people_outline, color: AppColors.primary),
                      _StatCard(title: 'Active Deals (Proposals)', value: '$activeDeals', icon: Icons.handshake_outlined, color: const Color(0xFF7C3AED)),
                      _StatCard(title: 'Pipeline Value', value: CurrencyFormatter.formatINR(pipelineValue), icon: Icons.account_balance_wallet_outlined, color: AppColors.success),
                      _StatCard(title: 'Win Rate', value: '${(state.metrics.overallWinRate * 100).toStringAsFixed(1)}%', icon: Icons.trending_up, color: AppColors.warning),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Recent Activity
            Text('Recent Activity', style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.lg),
            _ActivityItem(icon: Icons.phone, color: AppColors.error, title: 'Call with Nexbridge Tech', subtitle: 'Sarah Jenkins • 2 hrs ago'),
            _ActivityItem(icon: Icons.email, color: AppColors.primary, title: 'Email sent to Cloudverge', subtitle: 'M. Chen • 4 hrs ago'),
            _ActivityItem(icon: Icons.swap_horiz, color: AppColors.success, title: 'Lead converted: DataSpire Analytics', subtitle: 'Karthick • Yesterday'),
            _ActivityItem(icon: Icons.note_add, color: const Color(0xFFD97706), title: 'Note added on TechCorp deal', subtitle: 'Sarah Jenkins • Yesterday'),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  final String title; final String value; final IconData icon; final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              const Icon(Icons.trending_up, size: 16, color: AppColors.success),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle});
  final IconData icon; final Color color; final String title; final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
