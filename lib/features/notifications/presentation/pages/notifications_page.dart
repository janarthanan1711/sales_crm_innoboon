import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../app/di/injector.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notification_bloc.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationBloc>()..add(const NotificationLoadRequested()),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final padding = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: AppTextStyles.h1),
                    const SizedBox(height: 4),
                    Text(
                      'Stay updated with your tasks and deals',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    context.read<NotificationBloc>().add(const NotificationMarkedAllRead());
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all as read'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  if (state is NotificationLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotificationError) {
                    return Center(
                      child: Text(state.message, style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (state is NotificationLoaded) {
                    if (state.notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: AppSpacing.md),
                            Text('No notifications', style: AppTextStyles.h3),
                            Text('You\'re all caught up!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.separated(
                      itemCount: state.notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return _NotificationCard(notification: state.notifications[index]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.cardBackground : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIconBgColor(notification.type),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notification.type),
              size: 20,
              color: _getIconColor(notification.type),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatDate(notification.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead) ...[
            const SizedBox(width: AppSpacing.md),
            IconButton(
              onPressed: () {
                context.read<NotificationBloc>().add(NotificationMarkedRead(notification.id));
              },
              icon: const Icon(Icons.circle, size: 12, color: AppColors.primary),
              tooltip: 'Mark as read',
            ),
          ]
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.leadAssigned: return Icons.person_add;
      case NotificationType.dealStageChanged: return Icons.trending_up;
      case NotificationType.taskDue: return Icons.access_time;
      case NotificationType.mention: return Icons.alternate_email;
      case NotificationType.system: return Icons.info_outline;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.leadAssigned: return AppColors.success;
      case NotificationType.dealStageChanged: return AppColors.primary;
      case NotificationType.taskDue: return AppColors.warning;
      case NotificationType.mention: return AppColors.primary;
      case NotificationType.system: return AppColors.textSecondary;
    }
  }

  Color _getIconBgColor(NotificationType type) {
    return _getIconColor(type).withValues(alpha: 0.1);
  }
}
