import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/checklist_item.dart';
import '../bloc/checklist_bloc.dart';

class ChecklistView extends StatelessWidget {
  const ChecklistView({super.key, required this.dealId});
  final String dealId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChecklistBloc>()..add(ChecklistLoadForDealRequested(dealId)),
      child: const _ChecklistContent(),
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  const _ChecklistContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      builder: (context, state) {
        if (state is ChecklistLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ChecklistError) {
          return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
        }
        if (state is ChecklistLoaded) {
          if (state.stages.isEmpty) {
            return const EmptyState(
              icon: Icons.checklist,
              title: 'No Checklist',
              subtitle: 'No pre-sales checklist is attached to this deal.',
            );
          }
          
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.stages.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xl),
            itemBuilder: (context, index) {
              return _StageCard(stage: state.stages[index]);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});
  final ChecklistStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stage ${stage.stageOrder}: ${stage.stageName}',
                  style: AppTextStyles.h3,
                ),
                Text(
                  '${stage.completedCount} / ${stage.totalCount} Complete',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          ...stage.items.map((item) => _ChecklistItemRow(item: item)),
        ],
      ),
    );
  }
}

class _ChecklistItemRow extends StatelessWidget {
  const _ChecklistItemRow({required this.item});
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isCompleted,
            onChanged: (value) {
              if (value != null) {
                context.read<ChecklistBloc>().add(ChecklistItemToggled(item.id, value));
              }
            },
            activeColor: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.itemText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.owningTeam, style: AppTextStyles.caption),
                    ),
                  ],
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.notes, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
