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
import '../../domain/entities/deal_activity.dart';
import '../../domain/entities/deal_enums.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../bloc/deal_detail_bloc.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';
import '../../../../core/utils/link_launcher.dart';

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
          if (state is DealDetailLoading) {
            return const AppLoadingIndicator(message: 'Loading deal...');
          }
          if (state is DealDetailError) {
            return ErrorState(message: state.message, onRetry: () {});
          }
          if (state is DealDetailLoaded) return _buildContent(context, state);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DealDetailLoaded state) {
    final deal = state.deal;
    return DefaultTabController(
      length: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          Material(
            color: AppColors.cardBackground,
            child: const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Deal Info'),
                Tab(text: 'Stakeholders'),
                Tab(text: 'Contact'),
                Tab(text: 'Checklist'),
                Tab(text: 'Documents'),
                Tab(text: 'Activity'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _dealInfoTab(deal),
                _stakeholdersTab(deal),
                _contactTab(deal),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: ChecklistView(dealId: deal.id),
                ),
                _documentsTab(context),
                _activityTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DealDetailLoaded state) {
    final deal = state.deal;
    final stages = state.stages;
    final currentSort = stages
        .where((s) => s.id == deal.stageId)
        .map((s) => s.sortOrder)
        .fold<int?>(null, (_, v) => v);
    return Container(
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
                              Flexible(
                                child: Text(
                                  deal.accountName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // Text('•', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                              // const SizedBox(width: AppSpacing.sm),
                              // Container(
                              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              //   decoration: BoxDecoration(
                              //     color: AppColors.primaryLight,
                              //     borderRadius: BorderRadius.circular(4),
                              //   ),
                              //   child: Text(deal.stageName, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                              // ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(deal.name, style: AppTextStyles.h1),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      CurrencyFormatter.formatINR(deal.value),
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Owner: ${deal.owner}',
                      style: AppTextStyles.bodySmall,
                    ),
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
                              Flexible(
                                child: Text(
                                  deal.accountName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '•',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  deal.stageName,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
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
                        Text(
                          CurrencyFormatter.formatINR(deal.value),
                          style: AppTextStyles.h2,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Owner: ${deal.owner}',
                          style: AppTextStyles.bodySmall,
                        ),
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
          // Stage progress stepper — a connected track with a node marking the
          // current stage, built from the dynamic pipeline stages.
          if (stages.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(stages.length, (i) {
                final s = stages[i];
                final isCurrent = s.id == deal.stageId;
                final isCompleted =
                    currentSort != null && s.sortOrder < currentSort;
                // The track is filled up to and including the current node.
                final leftColor = (isCompleted || isCurrent)
                    ? AppColors.primary
                    : AppColors.border;
                final rightColor = isCompleted
                    ? AppColors.primary
                    : AppColors.border;
                return Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 16,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == 0
                                    ? Colors.transparent
                                    : leftColor,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Container(
                                height: 3,
                                color: i == stages.length - 1
                                    ? Colors.transparent
                                    : rightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        s.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted),
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // ── Tab views ──────────────────────────────────────────
  Widget _dealInfoTab(Deal deal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Deal Information',
        child: Column(
          children: [
            _infoRow('Account', deal.accountName),
            _infoRow('Stage', deal.stageName),
            _infoRow('Value', CurrencyFormatter.formatINR(deal.value)),
            _infoRow('Tier', deal.tier),
            _infoRow('Owner', deal.owner),
            _infoRow('Description', deal.description),
            _infoRow('Payment Status', deal.paymentStatus),
            _infoRow(
              'Expected Close',
              deal.expectedCloseDate != null
                  ? DateFormatter.displayDate(deal.expectedCloseDate!)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _stakeholdersTab(Deal deal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Stakeholders',
        child: deal.stakeholders.isEmpty
            ? Text(
                'No stakeholders added yet.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Column(
                children: deal.stakeholders
                    .map(
                      (s) => Padding(
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
                                  Text(
                                    '${s.role} • ${s.email}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (s.isPrimary)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Primary',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
  }

  Widget _contactTab(Deal deal) {
    final primary = deal.stakeholders.where((s) => s.isPrimary).toList();
    final name = primary.isNotEmpty
        ? primary.first.name
        : (deal.contactName ?? '');
    final role = primary.isNotEmpty ? primary.first.role : '';
    final email = primary.isNotEmpty ? primary.first.email : '';
    if (name.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: EmptyState(
          icon: Icons.person_outline,
          title: 'No primary contact',
          subtitle: 'Set a primary stakeholder to see it here.',
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Primary Contact',
        child: Row(
          children: [
            InitialsAvatar(name: name, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  if (role.isNotEmpty)
                    Text(
                      role,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (email.isNotEmpty)
                    LinkText(text: email, email: email, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _documentsTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Documents',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.insert_drive_file_outlined,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No documents uploaded yet.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Upload proposals, NDAs, or contracts here — wiring lands with the documents API.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activityTab(BuildContext context, DealDetailLoaded state) {
    final canManage = context.can(Perms.dealsManage);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Stage History',
            child: _StageHistoryList(history: state.stageHistory, state: state),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Activity Timeline',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.activityBusy)
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (canManage)
                  TextButton.icon(
                    onPressed: () =>
                        _showLogActivityDialog(context, state.deal.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Log Activity'),
                  ),
              ],
            ),
            child: state.activities.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Text(
                      'No activity logged yet. Track calls, meetings, and notes here.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : Column(
                    children: state.activities
                        .map(
                          (a) => _DealActivityRow(
                            dealId: state.deal.id,
                            activity: a,
                            canManage: canManage,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogActivityDialog(BuildContext context, String dealId) {
    final bloc = context.read<DealDetailBloc>();
    String type = dealActivityTypeLabels.keys.first;
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Log Activity'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: dealActivityTypeLabels.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => type = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Title'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Short summary (e.g. Kick-off call)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Note'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'What happened?',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (noteController.text.trim().isEmpty) return;
                    bloc.add(
                      DealDetailActivityLogRequested(
                        dealId,
                        type: type,
                        title: titleController.text.trim().isEmpty
                            ? null
                            : titleController.text.trim(),
                        note: noteController.text.trim(),
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openEditDealDialog(BuildContext context, Deal deal) {
    final bloc = context.read<DealDetailBloc>();
    showDialog(
      context: context,
      builder: (_) => CreateDealDialog(deal: deal),
    ).then((result) {
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
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

const Map<String, IconData> _activityIcons = {
  'note': Icons.description_outlined,
  'meeting': Icons.event_outlined,
  'call': Icons.call_outlined,
  'comment': Icons.chat_bubble_outline,
  'follow_up': Icons.flag_outlined,
};

class _DealActivityRow extends StatelessWidget {
  const _DealActivityRow({
    required this.dealId,
    required this.activity,
    required this.canManage,
  });
  final String dealId;
  final DealActivity activity;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final title = activity.title;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              _activityIcons[activity.type] ?? Icons.circle,
              size: 16,
              color: AppColors.primary,
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
                    Flexible(
                      child: Text(
                        labelForWireValue(
                          dealActivityTypeLabels,
                          activity.type,
                        ),
                        style: AppTextStyles.labelLarge,
                      ),
                    ),
                    Text(
                      DateFormatter.dateTime(activity.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                if (title != null && title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(title, style: AppTextStyles.labelMedium),
                ],
                const SizedBox(height: 4),
                Text(activity.note, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  activity.updatedAt != null
                      ? 'Edited${activity.updatedByName != null ? ' by ${activity.updatedByName}' : ''}'
                      : 'Logged by ${activity.createdByName ?? 'User ${activity.createdBy}'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              tooltip: 'Edit',
              onPressed: () => _showEditDialog(context),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<DealDetailBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(
                DealDetailActivityDeleteRequested(dealId, '${activity.id}'),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final bloc = context.read<DealDetailBloc>();
    final titleController = TextEditingController(text: activity.title ?? '');
    final noteController = TextEditingController(text: activity.note);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The activity type is fixed once logged — show it read-only.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    labelForWireValue(dealActivityTypeLabels, activity.type),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Title'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Short summary',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Note'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.trim().isEmpty) return;
                bloc.add(
                  DealDetailActivityUpdateRequested(
                    dealId,
                    '${activity.id}',
                    title: titleController.text.trim(),
                    note: noteController.text.trim(),
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
      return Text(
        'No stage changes recorded yet.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      );
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
                      h.fromStageId != null
                          ? '$fromName → $toName'
                          : 'Set to $toName',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  Text(
                    DateFormatter.relativeTime(h.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              if (h.note != null && h.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  h.note!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
