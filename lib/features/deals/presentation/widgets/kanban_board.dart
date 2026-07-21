import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/deal.dart';
import '../bloc/deals_list_bloc.dart';

/// Sentinel distinguishing "user cancelled the note dialog" from "user left
/// the note blank and confirmed" (a legitimate `null` note).
const String _cancelled = '__cancelled__';

Future<String?> _showStageChangeNoteDialog(
  BuildContext context,
  Deal deal,
  DealStage newStage,
) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Move "${deal.name}" to ${newStage.name}?'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Note (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(_cancelled),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(
            controller.text.trim().isEmpty ? '' : controller.text.trim(),
          ),
          child: const Text('Move'),
        ),
      ],
    ),
  );
  if (result == null || result == _cancelled) return _cancelled;
  return result.isEmpty ? null : result;
}

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
      onAcceptWithDetails: (details) async {
        if (details.data.stage == stage) return;
        final bloc = context.read<DealsListBloc>();
        final note = await _showStageChangeNoteDialog(context, details.data, stage);
        if (note == _cancelled) return;
        bloc.add(DealsListStageUpdated(
          dealId: details.data.id,
          newStage: stage,
          note: note,
        ));
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
          Text(CurrencyFormatter.formatINR(deal.value), style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
