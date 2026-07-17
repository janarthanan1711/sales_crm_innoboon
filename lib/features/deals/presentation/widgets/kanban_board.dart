import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/deal.dart';
import '../bloc/deals_list_bloc.dart';

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({super.key, required this.deals});
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: DealStage.values.map((stage) {
          final stageDeals = deals.where((d) => d.stage == stage).toList();
          return _KanbanColumn(stage: stage, deals: stageDeals);
        }).toList(),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.stage, required this.deals});
  final DealStage stage;
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    final double totalValue = deals.fold(0, (sum, deal) => sum + deal.value);

    return DragTarget<Deal>(
      onAcceptWithDetails: (details) {
        if (details.data.stage != stage) {
          context.read<DealsListBloc>().add(DealsListStageUpdated(
            dealId: details.data.id,
            newStage: stage,
          ));
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: AppSpacing.lg),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty 
                ? AppColors.primaryLight 
                : AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(stage.name, style: AppTextStyles.labelLarge),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${deals.length}', style: AppTextStyles.caption),
                    ),
                  ],
                ),
              ),
              if (deals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.md),
                  child: Text(
                    CurrencyFormatter.formatINR(totalValue),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: deals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    return Draggable<Deal>(
                      data: deal,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        child: SizedBox(
                          width: 280,
                          child: _DealCard(deal: deal),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.5,
                        child: _DealCard(deal: deal),
                      ),
                      child: _DealCard(deal: deal),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deal.name, style: AppTextStyles.labelLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(deal.accountName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CurrencyFormatter.formatINR(deal.value), style: AppTextStyles.labelMedium),
              if (deal.tier == 'Strategic' || deal.tier == 'Diamond')
                const Icon(Icons.star, size: 16, color: Colors.amber)
            ],
          ),
        ],
      ),
    );
  }
}
