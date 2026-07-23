import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../bloc/deal_detail_bloc.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';

import 'create_deal_page.dart';

class DealDetailPage extends StatelessWidget {
  const DealDetailPage({super.key, required this.dealId});
  final String dealId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DealDetailBloc>()..add(DealDetailLoadRequested(dealId)),
      child: const _DealDetailView(),
    );
  }
}

class _DealDetailView extends StatelessWidget {
  const _DealDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<DealDetailBloc, DealDetailState>(
        builder: (context, state) {
          if (state is DealDetailLoading) return const AppLoadingIndicator(message: 'Loading deal...');
          if (state is DealDetailError) return ErrorState(message: state.message, onRetry: () {});
          if (state is DealDetailLoaded) return _buildContent(context, state);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DealDetailLoaded state) {
    final deal = state.deal;
    final stageHistory = state.stageHistory;
    final stages = state.stages;
    final currentSort = stages
        .where((s) => s.id == deal.stageId)
        .map((s) => s.sortOrder)
        .fold<int?>(null, (_, v) => v);
    return SingleChildScrollView(
      child: Column(
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
                context.isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => context.go('/deals'),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(deal.accountName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(deal.stageName, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(deal.name, style: AppTextStyles.h1),
                          const SizedBox(height: AppSpacing.lg),
                          Text(CurrencyFormatter.formatINR(deal.value), style: AppTextStyles.h2),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Owner: ${deal.owner}', style: AppTextStyles.bodySmall),
                          const SizedBox(height: AppSpacing.md),
                          if (context.can(Perms.dealsManage))
                            ElevatedButton.icon(
                              onPressed: () => _openEditDealDialog(context, deal),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit Deal'),
                            ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => context.go('/deals'),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(deal.accountName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(deal.stageName, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(deal.name, style: AppTextStyles.h1),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.formatINR(deal.value), style: AppTextStyles.h2),
                              const SizedBox(height: AppSpacing.xs),
                              Text('Owner: ${deal.owner}', style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.md),
                              if (context.can(Perms.dealsManage))
                                ElevatedButton.icon(
                                  onPressed: () => _openEditDealDialog(context, deal),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit Deal'),
                                ),
                            ],
                          ),
                        ],
                      ),
                
                const SizedBox(height: AppSpacing.xl),
                // Stage Progress Bar — built from the dynamic pipeline stages.
                if (stages.isNotEmpty)
                  Row(
                    children: stages.map((s) {
                      final isCurrent = s.id == deal.stageId;
                      final isCompleted = currentSort != null && s.sortOrder < currentSort;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary
                                : isCompleted ? AppColors.primaryLight : AppColors.border,
                            borderRadius: BorderRadius.horizontal(
                              left: s == stages.first ? const Radius.circular(4) : Radius.zero,
                              right: s == stages.last ? const Radius.circular(4) : Radius.zero,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.name,
                            style: AppTextStyles.caption.copyWith(
                              color: isCurrent ? Colors.white : (isCompleted ? AppColors.primary : AppColors.textMuted),
                              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          
          // ── Main Content Grid ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: context.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionCard(
                        title: 'Deal Information',
                        child: Column(
                          children: [
                            _infoRow('Description', deal.description),
                            _infoRow('Payment Status', deal.paymentStatus),
                            _infoRow('Expected Close', deal.expectedCloseDate != null ? '${deal.expectedCloseDate!.toLocal()}'.split(' ')[0] : 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionCard(
                        title: 'Stakeholders',
                        child: Column(
                          children: deal.stakeholders.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              children: [
                                InitialsAvatar(name: s.name, size: 36),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name, style: AppTextStyles.labelLarge),
                                      Text('${s.role} • ${s.email}', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ),
                                if (s.isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text('Primary', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                  ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionCard(
                        title: 'Pre-Sales Checklist',
                        child: SizedBox(
                          height: 400,
                          child: ChecklistView(dealId: deal.id),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SectionCard(
                        title: 'Stage History',
                        child: _StageHistoryList(history: stageHistory, state: state),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: Column(
                          children: [
                            SectionCard(
                              title: 'Deal Information',
                              child: Column(
                                children: [
                                  _infoRow('Description', deal.description),
                                  _infoRow('Payment Status', deal.paymentStatus),
                                  _infoRow('Expected Close', deal.expectedCloseDate != null ? '${deal.expectedCloseDate!.toLocal()}'.split(' ')[0] : 'N/A'),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCard(
                              title: 'Stakeholders',
                              child: Column(
                                children: deal.stakeholders.map((s) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                  child: Row(
                                    children: [
                                      InitialsAvatar(name: s.name, size: 36),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name, style: AppTextStyles.labelLarge),
                                            Text('${s.role} • ${s.email}', style: AppTextStyles.bodySmall),
                                          ],
                                        ),
                                      ),
                                      if (s.isPrimary)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text('Primary', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
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
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            SectionCard(
                              title: 'Pre-Sales Checklist',
                              child: SizedBox(
                                height: 400,
                                child: ChecklistView(dealId: deal.id),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SectionCard(
                              title: 'Stage History',
                              child: _StageHistoryList(history: stageHistory, state: state),
                            ),
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

  void _openEditDealDialog(BuildContext context, Deal deal) {
    final bloc = context.read<DealDetailBloc>();
    showDialog(context: context, builder: (_) => CreateDealDialog(deal: deal)).then((result) {
      if (result != null) bloc.add(DealDetailLoadRequested(deal.id));
    });
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _StageHistoryList extends StatelessWidget {
  const _StageHistoryList({required this.history, required this.state});
  final List<DealStageHistoryEntry> history;
  final DealDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Text('No stage changes recorded yet.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: history.map((h) {
        final toName = state.stageName(h.toStageId);
        final fromName = state.stageName(h.fromStageId);
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      h.fromStageId != null ? '$fromName → $toName' : 'Set to $toName',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  Text(DateFormatter.relativeTime(h.createdAt), style: AppTextStyles.caption),
                ],
              ),
              if (h.note != null && h.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(h.note!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
