import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
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

// "Overdue Tasks" is reachable via the "Filter by Type" dropdown, so it's not
// duplicated as a tab here.
enum _NotificationTab { all, unread }

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  _NotificationTab _tab = _NotificationTab.all;
  NotificationType? _typeFilter;
  final Set<int> _selectedIds = {};

  void _applyFilters() {
    _selectedIds.clear();
    context.read<NotificationBloc>().add(NotificationLoadRequested(
          unreadOnly: _tab == _NotificationTab.unread,
          typeFilter: _typeFilter,
        ));
  }

  void _toggleSelected(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

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
            const SizedBox(height: AppSpacing.lg),
            Builder(builder: (context) {
              final segmented = SegmentedButton<_NotificationTab>(
                segments: const [
                  ButtonSegment(value: _NotificationTab.all, label: Text('All Notifications')),
                  ButtonSegment(value: _NotificationTab.unread, label: Text('Unread Only')),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() {
                  _tab = s.first;
                  _applyFilters();
                }),
              );
              final typeFilter = _TypeFilterDropdown(
                value: _typeFilter,
                onChanged: (v) => setState(() {
                  _typeFilter = v;
                  _applyFilters();
                }),
              );
              // Stack on phones so the segmented control + type filter don't
              // overflow a narrow row.
              if (context.isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: segmented,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(alignment: Alignment.centerLeft, child: typeFilter),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: segmented),
                  const SizedBox(width: AppSpacing.sm),
                  typeFilter,
                ],
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocConsumer<NotificationBloc, NotificationState>(
                listener: (context, state) {
                  if (state is NotificationLoaded) {
                    // Drop selections that no longer exist (e.g. after delete).
                    final ids = state.notifications.map((n) => n.id).toSet();
                    _selectedIds.removeWhere((id) => !ids.contains(id));
                  }
                },
                builder: (context, state) {
                  if (state is NotificationLoading || state is NotificationInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is NotificationError) {
                    return Center(
                      child: Text(state.message, style: const TextStyle(color: Colors.red)),
                    );
                  }
                  if (state is NotificationLoaded) {
                    if (state.notifications.isEmpty) {
                      return _EmptyNotifications(onGoToDashboard: () => context.go(RoutePaths.dashboard));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedIds.isNotEmpty)
                          _BulkActionBar(
                            count: _selectedIds.length,
                            onMarkRead: () {
                              context.read<NotificationBloc>().add(NotificationsBulkMarkReadRequested(_selectedIds.toList()));
                              setState(_selectedIds.clear);
                            },
                            onDelete: () {
                              context.read<NotificationBloc>().add(NotificationsBulkDeleteRequested(_selectedIds.toList()));
                              setState(_selectedIds.clear);
                            },
                            onClear: () => setState(_selectedIds.clear),
                          ),
                        Expanded(
                          child: _GroupedNotificationList(
                            notifications: state.notifications,
                            selectedIds: _selectedIds,
                            onToggleSelected: _toggleSelected,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: state.hasMore
                              ? (state.isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : TextButton(
                                      onPressed: () => context.read<NotificationBloc>().add(const NotificationLoadMoreRequested()),
                                      child: const Text('Load Older Notifications'),
                                    ))
                              : Text(
                                  "You're all caught up — no older notifications.",
                                  style: AppTextStyles.caption,
                                ),
                        ),
                      ],
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

class _TypeFilterDropdown extends StatelessWidget {
  const _TypeFilterDropdown({required this.value, required this.onChanged});
  final NotificationType? value;
  final ValueChanged<NotificationType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<NotificationType?>(
          value: value,
          hint: const Text('Filter by Type'),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Types')),
            ...NotificationType.values.map(
              (t) => DropdownMenuItem(value: t, child: Text(notificationTypeLabels[notificationTypeWireValue(t)]!)),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.count,
    required this.onMarkRead,
    required this.onDelete,
    required this.onClear,
  });
  final int count;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 12, backgroundColor: AppColors.primary, child: Text('$count', style: const TextStyle(fontSize: 12, color: Colors.white))),
          const SizedBox(width: AppSpacing.sm),
          Text('$count selected', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          const Spacer(),
          TextButton.icon(
            onPressed: onMarkRead,
            icon: const Icon(Icons.mark_email_read_outlined, size: 16, color: Colors.white),
            label: const Text('Mark Read', style: TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
          IconButton(onPressed: onClear, icon: const Icon(Icons.close, size: 18, color: Colors.white)),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.onGoToDashboard});
  final VoidCallback onGoToDashboard;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.done_all, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text("You're all caught up!", style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'There are no new notifications. Check back later for updates on your deals, tasks, and team assignments.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onGoToDashboard,
            icon: const Icon(Icons.grid_view, size: 18),
            label: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }
}

class _GroupedNotificationList extends StatelessWidget {
  const _GroupedNotificationList({
    required this.notifications,
    required this.selectedIds,
    required this.onToggleSelected,
  });
  final List<AppNotification> notifications;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggleSelected;

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return 'Earlier This Week';
    return 'Older';
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<AppNotification>>{};
    for (final n in notifications) {
      groups.putIfAbsent(_groupLabel(n.createdAt), () => []).add(n);
    }
    const order = ['Today', 'Yesterday', 'Earlier This Week', 'Older'];
    final orderedKeys = order.where(groups.containsKey).toList();

    return ListView(
      children: [
        for (final key in orderedKeys) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(key.toUpperCase(), style: AppTextStyles.overline),
          ),
          ...groups[key]!.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _NotificationCard(
                notification: n,
                selected: selectedIds.contains(n.id),
                onToggleSelected: n.isComputed ? null : () => onToggleSelected(n.id),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.selected, required this.onToggleSelected});
  final AppNotification notification;
  final bool selected;
  /// Null when the notification is a computed `task_overdue` entry — those
  /// aren't stored rows so they can't be bulk-selected for read/delete.
  final VoidCallback? onToggleSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.cardBackground : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: selected, onChanged: onToggleSelected == null ? null : (_) => onToggleSelected!()),
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
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(_formatDate(notification.createdAt), style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle read/unread. Computed `task_overdue` entries aren't stored
          // rows, so they can't be toggled.
          if (!notification.isComputed) ...[
            const SizedBox(width: AppSpacing.md),
            IconButton(
              onPressed: () {
                final bloc = context.read<NotificationBloc>();
                if (notification.isRead) {
                  bloc.add(NotificationMarkedUnread(notification.id));
                } else {
                  bloc.add(NotificationMarkedRead(notification.id));
                }
              },
              icon: Icon(
                notification.isRead ? Icons.circle_outlined : Icons.circle,
                size: 12,
                color: notification.isRead ? AppColors.textMuted : AppColors.primary,
              ),
              tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
            ),
          ],
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
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.leadAssigned: return Icons.person_add;
      case NotificationType.dealStageChanged: return Icons.trending_up;
      case NotificationType.taskOverdue: return Icons.access_time;
      case NotificationType.newLead: return Icons.star_outline;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.leadAssigned: return AppColors.success;
      case NotificationType.dealStageChanged: return AppColors.primary;
      case NotificationType.taskOverdue: return AppColors.warning;
      case NotificationType.newLead: return AppColors.primary;
    }
  }

  Color _getIconBgColor(NotificationType type) {
    return _getIconColor(type).withValues(alpha: 0.1);
  }
}
