import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_activity.dart';
import '../../domain/entities/deal_enums.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../bloc/deal_detail_bloc.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../documents/domain/entities/deal_document.dart';
import '../../../documents/domain/usecases/document_usecases.dart';

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
                _stakeholdersTab(context, deal),
                _contactTab(deal),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: ChecklistView(dealId: deal.id),
                ),
                _DealDocumentsTab(dealId: deal.id),
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
          // Stage progress stepper — a connected node-track built from the
          // dynamic pipeline stages: completed stages show a filled check
          // node, the current stage an emphasized ring, upcoming stages a
          // hollow node.
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
                        height: 30,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? Colors.transparent
                                      : leftColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            _StepNode(
                              index: i,
                              isCompleted: isCompleted,
                              isCurrent: isCurrent,
                            ),
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: i == stages.length - 1
                                      ? Colors.transparent
                                      : rightColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
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
    final close = deal.expectedCloseDate;
    String? remaining;
    Color remainingColor = AppColors.textMuted;
    if (close != null) {
      final days = close.difference(DateTime.now()).inDays;
      if (days > 0) {
        remaining = '$days days remaining';
      } else if (days == 0) {
        remaining = 'Due today';
        remainingColor = AppColors.error;
      } else {
        remaining = 'Overdue by ${-days} days';
        remainingColor = AppColors.error;
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Deal Information',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Account', deal.accountName),
            _infoRow('Stage', deal.stageName),
            _infoRow('Value', CurrencyFormatter.formatINR(deal.value)),
            _infoRowWidget(
              'Tier',
              deal.tier.isNotEmpty
                  ? TierBadge(tier: deal.tier)
                  : Text('—', style: AppTextStyles.bodyMedium),
            ),
            _infoRow('Owner', deal.owner),
            _infoRow(
              'Description',
              deal.description.isEmpty ? '—' : deal.description,
            ),
            _infoRowWidget('Payment Status', _statusBadge(deal.paymentStatus)),
            _infoRowWidget(
              'Expected Close',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    close != null
                        ? DateFormatter.displayDate(close)
                        : 'N/A',
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (remaining != null)
                    Text(
                      '($remaining)',
                      style: AppTextStyles.caption.copyWith(color: remainingColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stakeholdersTab(BuildContext context, Deal deal) {
    final canManage = context.can(Perms.dealsManage);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Stakeholders',
        trailing: canManage
            ? TextButton.icon(
                onPressed: () => _comingSoon(context, 'Stakeholder management'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Stakeholder'),
              )
            : null,
        child: deal.stakeholders.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No stakeholders added yet.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  // Table header
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(flex: 4, child: Text('NAME', style: AppTextStyles.tableHeader)),
                        Expanded(flex: 3, child: Text('ROLE', style: AppTextStyles.tableHeader)),
                        Expanded(flex: 5, child: Text('EMAIL', style: AppTextStyles.tableHeader)),
                        Expanded(flex: 3, child: Text('DECISION MAKER', style: AppTextStyles.tableHeader)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ...deal.stakeholders.map(
                    (s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              s.name,
                              style: AppTextStyles.labelMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              s.role.isEmpty ? '—' : s.role,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: s.email.isEmpty
                                ? Text('—', style: AppTextStyles.bodySmall)
                                : LinkText(text: s.email, email: s.email, maxLines: 1),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _decisionCheck(s.isPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _decisionCheck(bool checked) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: checked ? AppColors.primary : AppColors.border,
        ),
      ),
      child: checked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
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

  Widget _activityTab(BuildContext context, DealDetailLoaded state) {
    final canManage = context.can(Perms.dealsManage);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
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
                onPressed: () => _showLogActivityDialog(context, state.deal.id),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Log Activity'),
              ),
          ],
        ),
        child: _ActivityTimeline(state: state, canManage: canManage),
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
    return _infoRowWidget(label, Text(value, style: AppTextStyles.bodyMedium));
  }

  Widget _infoRowWidget(String label, Widget value) {
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
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: value),
          ),
        ],
      ),
    );
  }
}

/// A single stage node in the deal progress stepper.
/// - completed → filled primary circle with a white check
/// - current   → filled primary circle with a soft outer ring
/// - upcoming  → hollow circle with the (1-based) stage number
class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });
  final int index;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final node = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: (isCompleted || isCurrent)
            ? AppColors.primary
            : AppColors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: (isCompleted || isCurrent)
              ? AppColors.primary
              : AppColors.border,
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 15, color: Colors.white)
          : Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                color: isCurrent ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
    );
    if (!isCurrent) return node;
    // The current stage gets a soft ring to stand out on the track.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      child: node,
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
    final typeLabel = labelForWireValue(dealActivityTypeLabels, activity.type);
    // Heading mirrors the figma: "<Type>: <title or note>".
    final heading = (title != null && title.isNotEmpty)
        ? '$typeLabel: $title'
        : '$typeLabel: ${activity.note}';
    // When a title is set, the note is shown as a secondary line.
    final secondary = (title != null && title.isNotEmpty && activity.note.isNotEmpty)
        ? activity.note
        : null;
    final byline = activity.updatedAt != null
        ? 'Edited${activity.updatedByName != null ? ' by ${activity.updatedByName}' : ''}'
        : (activity.createdByName ?? 'User ${activity.createdBy}');

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: AppTextStyles.labelMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                DateFormatter.dateTime(activity.createdAt),
                style: AppTextStyles.caption,
              ),
              if (canManage) ...[
                InkWell(
                  onTap: () => _showEditDialog(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDelete(context),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
          if (secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              secondary,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  byline,
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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

/// Node accent colors per activity type (drives the timeline dots).
const Map<String, Color> _activityColors = {
  'note': Color(0xFF8B5CF6),
  'meeting': Color(0xFF3B82F6),
  'call': Color(0xFFF97316),
  'comment': Color(0xFF06B6D4),
  'follow_up': Color(0xFF10B981),
};

/// A single item in the merged timeline — either a logged activity or a
/// stage-change entry.
class _TimelineEntry {
  final DateTime date;
  final DealActivity? activity;
  final DealStageHistoryEntry? stageMove;
  const _TimelineEntry({required this.date, this.activity, this.stageMove});
}

/// The deal Activity tab body — a vertical timeline that merges logged
/// activities and stage-change history, newest first, matching the figma.
class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.state, required this.canManage});
  final DealDetailLoaded state;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final entries = <_TimelineEntry>[
      for (final a in state.activities)
        _TimelineEntry(date: a.createdAt, activity: a),
      for (final h in state.stageHistory)
        _TimelineEntry(date: h.createdAt, stageMove: h),
    ]..sort((a, b) => b.date.compareTo(a.date));

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No activity logged yet. Track calls, meetings, and notes here.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: List.generate(entries.length, (i) {
        return _TimelineRow(
          entry: entries[i],
          isLast: i == entries.length - 1,
          state: state,
          canManage: canManage,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.isLast,
    required this.state,
    required this.canManage,
  });
  final _TimelineEntry entry;
  final bool isLast;
  final DealDetailLoaded state;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final activity = entry.activity;
    final node = activity != null
        ? _activityNode(activity)
        : const _StageNode();
    final content = activity != null
        ? _DealActivityRow(
            dealId: state.deal.id,
            activity: activity,
            canManage: canManage,
          )
        : _StageMoveContent(entry: entry.stageMove!, state: state);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              node,
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : AppColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityNode(DealActivity a) {
    final color = _activityColors[a.type] ?? AppColors.primary;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        _activityIcons[a.type] ?? Icons.circle,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

class _StageNode extends StatelessWidget {
  const _StageNode();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textMuted, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Inline (non-card) timeline entry for a stage change, e.g.
/// "Stage moved from Evaluation to Proposals".
class _StageMoveContent extends StatelessWidget {
  const _StageMoveContent({required this.entry, required this.state});
  final DealStageHistoryEntry entry;
  final DealDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final toName = state.stageName(entry.toStageId);
    final fromName = state.stageName(entry.fromStageId);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              children: entry.fromStageId != null
                  ? [
                      const TextSpan(text: 'Stage moved from '),
                      TextSpan(
                        text: fromName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const TextSpan(text: ' to '),
                      TextSpan(
                        text: toName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ]
                  : [
                      const TextSpan(text: 'Stage set to '),
                      TextSpan(
                        text: toName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormatter.dateTime(entry.createdAt),
            style: AppTextStyles.caption,
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.note!,
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Turns a relative `/media/...` document path into an absolute URL. Files are
/// served from the server origin (not under the `/api/v1` prefix), so strip
/// that suffix from the Dio base URL before joining.
String _mediaUrl(String fileUrl) {
  if (fileUrl.startsWith('http')) return fileUrl;
  final base = sl<DioClient>().dio.options.baseUrl;
  final origin = base.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
  final path = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
  return '$origin$path';
}

/// Deal → Documents tab. Wired to `/deals/{id}/documents` — list, upload
/// (multipart), view (opens the file's `/media/...` URL) and delete. The
/// backend has no document-edit endpoint, so rows are view/delete only.
class _DealDocumentsTab extends StatefulWidget {
  const _DealDocumentsTab({required this.dealId});
  final String dealId;

  @override
  State<_DealDocumentsTab> createState() => _DealDocumentsTabState();
}

class _DealDocumentsTabState extends State<_DealDocumentsTab> {
  final List<DealDocument> _all = [];
  final Map<int, String> _userNames = {};
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docsResult = await sl<GetDealDocumentsUseCase>()(widget.dealId);
    final usersResult = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    usersResult.fold((_) {}, (users) {
      _userNames
        ..clear()
        ..addEntries(users.map((u) => MapEntry(u.id, u.displayName)));
    });
    docsResult.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (docs) => setState(() {
        _loading = false;
        _error = null;
        _all
          ..clear()
          ..addAll(docs);
      }),
    );
  }

  String _uploaderName(int id) => _userNames[id] ?? 'User $id';

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    // withData: true so we get bytes for the multipart body (works on web too).
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    final Uint8List? bytes = f.bytes;
    if (bytes == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not read the selected file.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _uploading = true);
    final result = await sl<UploadDealDocumentUseCase>()(
      UploadDealDocumentParams(
        dealId: widget.dealId,
        bytes: bytes,
        fileName: f.name,
      ),
    );
    if (!mounted) return;
    result.fold(
      (fail) {
        setState(() => _uploading = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Upload failed: ${fail.message}'),
          backgroundColor: AppColors.error,
        ));
      },
      (doc) {
        messenger.showSnackBar(SnackBar(content: Text('“${f.name}” uploaded.')));
        // Reflect immediately from the authoritative upload response — a
        // follow-up GET can race the server's write and return a stale list,
        // so insert the returned document directly instead of re-fetching.
        setState(() {
          _uploading = false;
          _all.removeWhere((d) => d.id == doc.id);
          _all.insert(0, doc);
        });
      },
    );
  }

  Future<void> _delete(DealDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Remove “${doc.name}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await sl<DeleteDealDocumentUseCase>()(
      DeleteDealDocumentParams(dealId: widget.dealId, documentId: doc.id),
    );
    if (!mounted) return;
    result.fold(
      (f) => messenger.showSnackBar(SnackBar(
        content: Text('Failed to delete: ${f.message}'),
        backgroundColor: AppColors.error,
      )),
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Document deleted.')),
        );
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.can(Perms.dealsManage);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: 'Documents',
        trailing: canManage
            ? TextButton.icon(
                onPressed: _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_outlined, size: 18),
                label: Text(_uploading ? 'Uploading...' : 'Upload'),
              )
            : null,
        child: _buildBody(canManage),
      ),
    );
  }

  Widget _buildBody(bool canManage) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: ErrorState(message: _error!, onRetry: _load),
      );
    }
    if (_all.isEmpty) {
      return InkWell(
        onTap: canManage && !_uploading ? _upload : null,
        borderRadius: BorderRadius.circular(8),
        child: DottedBorder(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl * 1.5),
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
                  canManage
                      ? 'Upload proposals, NDAs, or contracts here.'
                      : 'Documents shared on this deal appear here.',
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
    return Column(
      children: [
        for (int i = 0; i < _all.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _DealDocumentRow(
            document: _all[i],
            uploaderName: _uploaderName(_all[i].uploadedBy),
            canManage: canManage,
            onView: () => launchWebUrl(_mediaUrl(_all[i].fileUrl)),
            onDelete: () => _delete(_all[i]),
          ),
        ],
      ],
    );
  }
}

class _DealDocumentRow extends StatelessWidget {
  const _DealDocumentRow({
    required this.document,
    required this.uploaderName,
    required this.canManage,
    required this.onView,
    required this.onDelete,
  });
  final DealDocument document;
  final String uploaderName;
  final bool canManage;
  final VoidCallback onView;
  final VoidCallback onDelete;

  IconData _icon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      case 'docx':
      case 'doc':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _typeLabel() {
    final ext = document.extension;
    if (ext.isNotEmpty) return ext.toUpperCase();
    return document.contentType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(_icon(document.extension), size: 24, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: AppTextStyles.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_typeLabel()} · $uploaderName · ${DateFormatter.displayDate(document.createdAt)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'View',
            icon: const Icon(Icons.open_in_new, size: 18),
            color: AppColors.textSecondary,
            onPressed: onView,
          ),
          if (canManage)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline, size: 18),
              color: AppColors.error,
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

/// A rounded rectangle with a dashed border — used for the Documents drop zone.
class DottedBorder extends StatelessWidget {
  const DottedBorder({super.key, required this.child, this.radius = 8});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(radius: radius),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.radius});
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, dist + dash),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}
