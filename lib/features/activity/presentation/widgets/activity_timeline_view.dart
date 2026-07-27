import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/activity.dart';
import '../bloc/activity_bloc.dart';

class ActivityTimelineView extends StatelessWidget {
  const ActivityTimelineView({super.key, required this.entityType, required this.entityId});
  final String entityType;
  final String entityId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ActivityBloc>()..add(ActivityLoadRequested(entityType, entityId)),
      child: const _ActivityContent(),
    );
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Activity Log', style: AppTextStyles.h2),
            ElevatedButton.icon(
              onPressed: () {}, // Open Log Activity Dialog
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Activity'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<ActivityBloc, ActivityState>(
          builder: (context, state) {
            if (state is ActivityLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ActivityError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            if (state is ActivityLoaded) {
              if (state.activities.isEmpty) {
                return const EmptyState(
                  icon: Icons.history,
                  title: 'No activity yet',
                  subtitle: 'Log an activity to track progress.',
                );
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.activities.length,
                itemBuilder: (context, index) {
                  return _TimelineItem(
                    activity: state.activities[index],
                    isLast: index == state.activities.length - 1,
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.activity, required this.isLast});
  final AppActivity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getIconBgColor(activity.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(activity.type),
                    size: 16,
                    color: _getIconColor(activity.type),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activity.title, style: AppTextStyles.labelLarge),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(activity.performedAt.toLocal()),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(activity.description, style: AppTextStyles.bodyMedium),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(activity.performedBy, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(ActivityType type) {
    switch (type) {
      case ActivityType.call: return Icons.phone;
      case ActivityType.email: return Icons.email;
      case ActivityType.meeting: return Icons.event;
      case ActivityType.note: return Icons.note;
      case ActivityType.stageChange: return Icons.swap_horiz;
      case ActivityType.taskComplete: return Icons.check_circle;
    }
  }

  Color _getIconColor(ActivityType type) {
    switch (type) {
      case ActivityType.call: return AppColors.error;
      case ActivityType.email: return AppColors.primary;
      case ActivityType.meeting: return AppColors.success;
      case ActivityType.note: return AppColors.warning;
      case ActivityType.stageChange: return AppColors.primary;
      case ActivityType.taskComplete: return AppColors.success;
    }
  }

  Color _getIconBgColor(ActivityType type) {
    return _getIconColor(type).withValues(alpha: 0.1);
  }
}
