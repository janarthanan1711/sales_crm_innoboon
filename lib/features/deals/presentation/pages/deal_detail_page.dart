import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/deal.dart';
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
          if (state is DealDetailLoaded) return _buildContent(context, state.deal);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Deal deal) {
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
                                      child: Text(deal.stage.name, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(child: Text(deal.name, style: AppTextStyles.h1)),
                              const SizedBox(width: AppSpacing.md),
                              TierBadge(tier: deal.tier),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(CurrencyFormatter.formatINR(deal.value), style: AppTextStyles.h2),
                          const SizedBox(height: AppSpacing.xs),
                          Text('Owner: ${deal.owner}', style: AppTextStyles.bodySmall),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => CreateDealDialog(deal: deal),
                            ),
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
                                      child: Text(deal.stage.name, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Text(deal.name, style: AppTextStyles.h1),
                                    const SizedBox(width: AppSpacing.md),
                                    TierBadge(tier: deal.tier),
                                  ],
                                ),
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
                              ElevatedButton.icon(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => CreateDealDialog(deal: deal),
                                ),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Deal'),
                              ),
                            ],
                          ),
                        ],
                      ),
                
                const SizedBox(height: AppSpacing.xl),
                // Stage Progress Bar (simplified)
                Row(
                  children: DealStage.values.map((s) {
                    final isCompleted = s.index < deal.stage.index;
                    final isCurrent = s.index == deal.stage.index;
                    
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrent 
                              ? AppColors.primary 
                              : isCompleted ? AppColors.primaryLight : AppColors.border,
                          borderRadius: BorderRadius.horizontal(
                            left: s == DealStage.values.first ? const Radius.circular(4) : Radius.zero,
                            right: s == DealStage.values.last ? const Radius.circular(4) : Radius.zero,
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
