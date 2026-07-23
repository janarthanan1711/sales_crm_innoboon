import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../bloc/deals_list_bloc.dart';

const String _cancelled = '__cancelled__';

/// Result of the move dialog: cancelled, or a confirmed (note, coldReason).
class _MoveResult {
  final String? note;
  final String? coldReason;
  const _MoveResult({this.note, this.coldReason});
}

Future<_MoveResult?> _showMoveDialog(
  BuildContext context,
  Deal deal,
  DealStageDef target,
) async {
  final noteController = TextEditingController();
  final coldController = TextEditingController();
  final result = await showDialog<Object>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Move "${deal.name}" to ${target.name}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (target.isCold)
            TextField(
              controller: coldController,
              decoration: const InputDecoration(
                labelText: 'Cold reason *',
                helperText: 'Required when moving to a cold stage',
                border: OutlineInputBorder(),
              ),
            ),
          if (target.isCold) const SizedBox(height: AppSpacing.md),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(_cancelled),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (target.isCold && coldController.text.trim().isEmpty) return;
            Navigator.of(dialogContext).pop(
              _MoveResult(
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                coldReason: coldController.text.trim().isEmpty
                    ? null
                    : coldController.text.trim(),
              ),
            );
          },
          child: const Text('Move'),
        ),
      ],
    ),
  );
  if (result == null || result == _cancelled) return null;
  return result as _MoveResult;
}

class KanbanBoard extends StatelessWidget {
  const KanbanBoard({
    super.key,
    required this.deals,
    required this.stages,
    this.canManage = true,
  });
  final List<Deal> deals;
  final List<DealStageDef> stages;

  /// When false (user lacks `deals.access`), cards are not draggable and
  /// drop targets reject moves — the board is view-only.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stages.map((stage) {
          final stageDeals = deals.where((d) => d.stageId == stage.id).toList();
          return _KanbanColumn(
            stage: stage,
            deals: stageDeals,
            canManage: canManage,
          );
        }).toList(),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({
    required this.stage,
    required this.deals,
    required this.canManage,
  });
  final DealStageDef stage;
  final List<Deal> deals;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final double totalValue = deals.fold(0, (sum, deal) => sum + deal.value);

    return DragTarget<Deal>(
      onWillAcceptWithDetails: (details) =>
          canManage && details.data.stageId != stage.id,
      onAcceptWithDetails: (details) async {
        final bloc = context.read<DealsListBloc>();
        final move = await _showMoveDialog(context, details.data, stage);
        if (move == null) return;
        bloc.add(
          DealsListStageUpdated(
            dealId: details.data.id,
            newStageId: stage.id,
            note: move.note,
            coldReason: move.coldReason,
          ),
        );
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
                    Flexible(
                      child: Text(
                        stage.name,
                        style: AppTextStyles.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deals.length}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              if (deals.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ).copyWith(bottom: AppSpacing.md),
                  child: Text(
                    CurrencyFormatter.formatINR(totalValue),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              // A fixed-height scroll area so empty columns are still valid
              // drop targets.
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  itemCount: deals.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final deal = deals[index];
                    if (!canManage) return _DealCard(deal: deal);
                    return Draggable<Deal>(
                      data: deal,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
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
          Text(
            deal.name,
            style: AppTextStyles.labelLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            deal.accountName,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            CurrencyFormatter.formatINR(deal.value),
            style: AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
