import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/account.dart';
import '../bloc/account_detail_bloc.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';
import '../../../../features/activity/presentation/widgets/activity_timeline_view.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountDetailBloc>()..add(AccountDetailLoadRequested(accountId)),
      child: const _AccountDetailView(),
    );
  }
}

class _AccountDetailView extends StatefulWidget {
  const _AccountDetailView();

  @override
  State<_AccountDetailView> createState() => _AccountDetailViewState();
}

class _AccountDetailViewState extends State<_AccountDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AccountDetailBloc, AccountDetailState>(
        builder: (context, state) {
          if (state is AccountDetailLoading) return const AppLoadingIndicator(message: 'Loading account...');
          if (state is AccountDetailError) return ErrorState(message: state.message, onRetry: () {});
          if (state is AccountDetailLoaded) return _buildContent(context, state.account);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Account account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/accounts'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  InitialsAvatar(name: account.companyName, size: 48),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(account.companyName, style: AppTextStyles.h1),
                            const SizedBox(width: AppSpacing.md),
                            TierBadge(tier: account.tier),
                          ],
                        ),
                        Text(account.domain, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Account'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Deal'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Tabs ─────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelLarge,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Contacts'),
            Tab(text: 'Deals'),
            Tab(text: 'Pre-Sales Checklist'),
            Tab(text: 'Activity Log'),
          ],
        ),
        
        // ── Tab Content ──────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(account: account),
              const Center(child: Text('Contacts (Coming soon)')),
              const Center(child: Text('Deals (Coming soon)')),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ChecklistView(dealId: 'deal_001'), // Should use deal context or be modified for account
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ActivityTimelineView(entityType: 'Account', entityId: account.id),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column (Main info)
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Account Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Industry', account.industry),
                      _infoRow('Primary Owner', account.primaryOwner),
                      _infoRow('Description', account.description),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  title: 'Primary Contacts',
                  child: account.contacts.isEmpty 
                    ? const Text('No contacts added yet')
                    : Column(
                        children: account.contacts.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              InitialsAvatar(name: c.name, size: 36),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(c.name, style: AppTextStyles.labelLarge),
                                        if (c.isDecisionMaker) ...[
                                          const SizedBox(width: AppSpacing.xs),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text('Decision Maker', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('${c.role} • ${c.email}', style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxl),
          
          // Right column (Side panels)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Quick Stats',
                  child: Column(
                    children: [
                      _statRow('Active Deals', '${account.activeDealsCount}', Icons.handshake_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _statRow('Total Contacts', '${account.contacts.length}', Icons.people_outline),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value, style: AppTextStyles.h3),
      ],
    );
  }
}
