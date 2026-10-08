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
import '../../../../core/widgets/record_export_button.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../app/di/injector.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../../accounts/presentation/widgets/person_type_icon.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_activity.dart';
import '../../domain/entities/deal_contact.dart';
import '../../domain/entities/deal_enums.dart';
import '../../domain/entities/deal_stage_history.dart';
import '../../domain/usecases/export_deals_usecase.dart';
import '../../domain/usecases/update_deal_usecase.dart';
import '../bloc/deal_detail_bloc.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/domain/usecases/contact_usecases.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../documents/domain/entities/deal_document.dart';
import '../../../documents/domain/usecases/document_usecases.dart';

import '../widgets/qualification_card.dart';
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
      body: BlocConsumer<DealDetailBloc, DealDetailState>(
        listener: (context, state) {
          if (state is DealDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deal deleted.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/deals');
          }
        },
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
    // Stakeholders and Checklist tabs were removed ahead of deployment:
    // stakeholders had no endpoint (in-memory only) and the checklist was
    // mock-backed.
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, state),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: TabBar(
                isScrollable: true,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.tab,
                tabAlignment: TabAlignment.start,
                tabs: [
                  _iconTab(Icons.receipt_long_outlined, 'Deal Info'),
                  _iconTab(
                    Icons.contacts_outlined,
                    'Contacts',
                    count: deal.contacts.length,
                  ),
                  _iconTab(Icons.folder_outlined, 'Documents'),
                  _iconTab(Icons.history, 'Activity'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _dealInfoTab(context, deal),
                _ContactsTab(deal: deal),
                _DealDocumentsTab(dealId: deal.id),
                _activityTab(context, state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Tab _iconTab(IconData icon, String label, {int? count}) {
    return Tab(
      height: 44,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
          if (count != null && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppSpacing.badgeRadius),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.badge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DealDetailLoaded state) {
    final deal = state.deal;
    final stages = state.stages;
    final canManage = context.can(Perms.dealsManage);
    final currentIndex = stages.indexWhere((s) => s.id == deal.stageId);

    final breadcrumb = Row(
      children: [
        InkWell(
          onTap: () => context.go('/deals'),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Back to Deals',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          '  /  ',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted),
        ),
        Flexible(
          child: Text(
            deal.accountName,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '  •  ${deal.stageLabel}',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        if (!context.isMobile)
          Text(
            'DL-${deal.id}  •  Created ${DateFormatter.displayDate(deal.createdAt)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );

    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _exportButton(deal),
        if (canManage) ...[
          ElevatedButton.icon(
            onPressed: () => _openEditDealDialog(context, deal),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Deal'),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: SizedBox(
              height: AppSpacing.buttonHeight - 2,
              width: AppSpacing.buttonHeight - 2,
              child: _deleteMenuButton(context, deal),
            ),
          ),
        ],
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            StatusBadge.dealStage(deal.stageLabel),
            if (deal.tier.isNotEmpty) StatusBadge.tier(deal.tier),
            if (deal.priority != null) StatusBadge.priority(deal.priority!),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(deal.name, style: AppTextStyles.h1),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('VALUE', style: AppTextStyles.tableHeader),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  CurrencyFormatter.formatINR(deal.value),
                  style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Owner: ', style: AppTextStyles.bodySmall),
                OwnerChip(name: deal.ownerLabel),
              ],
            ),
          ],
        ),
      ],
    );

    final close = deal.expectedCloseDate;
    final stats = Wrap(
      spacing: AppSpacing.huge,
      runSpacing: AppSpacing.lg,
      children: [
        MetaStat(
          label: 'Score',
          value: Text(
            deal.totalScore == null ? 'Not scored' : '${deal.totalScore}',
            style: TextStyle(
              color: deal.totalScore == null ? AppColors.error : null,
            ),
          ),
        ),
        MetaStat(label: 'Priority', value: Text(deal.priority ?? '—')),
        MetaStat(
          label: 'Expected close',
          value: Text(close == null ? '—' : DateFormatter.displayDate(close)),
        ),
        MetaStat(
          label: 'Proposal sent',
          value: Text(
            deal.proposalStatus == 'proposal_sent'
                ? (deal.proposalSentAt == null
                      ? 'Sent'
                      : DateFormatter.displayDate(deal.proposalSentAt!))
                : 'Not sent',
          ),
        ),
        MetaStat(
          label: 'Proposal SLA',
          value: Text(deal.proposalSla ?? 'Not set'),
        ),
        MetaStat(
          label: 'Next follow-up',
          value: Text(
            deal.followUpDate == null
                ? 'Not set'
                : DateFormatter.displayDate(deal.followUpDate!),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          breadcrumb,
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: appCardDecoration(radius: AppSpacing.cardRadiusLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                context.isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleBlock,
                          const SizedBox(height: AppSpacing.lg),
                          actions,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: titleBlock),
                          const SizedBox(width: AppSpacing.lg),
                          actions,
                        ],
                      ),
                if (stages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SegmentedStageBar(
                    stages: stages.map((s) => s.name).toList(),
                    currentIndex: currentIndex,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                stats,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single-deal xlsx export. Read-only, so it's not gated behind
  /// `deals.manage` — anyone who can open the deal can download it.
  Widget _exportButton(Deal deal) {
    return RecordExportButton(
      fileName: 'deal_${deal.id}.xlsx',
      successMessage: 'Deal exported.',
      fetch: () => sl<ExportDealDetailUseCase>()(deal.id),
    );
  }

  Widget _deleteMenuButton(BuildContext context, Deal deal) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'delete') _confirmDeleteDeal(context, deal);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              SizedBox(width: AppSpacing.sm),
              Text('Delete Deal', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteDeal(BuildContext context, Deal deal) {
    final bloc = context.read<DealDetailBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete deal?'),
        content: Text(
          'This will permanently delete "${deal.name}" and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(DealDetailDeleteRequested(deal.id));
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ── Tab views ──────────────────────────────────────────
  Widget _dealInfoTab(BuildContext context, Deal deal) {
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
    final info = SectionCard(
      title: 'Deal Information',
      child: InfoGrid(
        items: [
          _kv('Account', deal.accountName),
          _kv('Stage', deal.stageLabel),
          _kv('Value', CurrencyFormatter.formatINR(deal.value)),
          (
            'Tier',
            deal.tier.isNotEmpty
                ? TierBadge(tier: deal.tier)
                : Text('—', style: AppTextStyles.bodyMedium),
          ),
          _kv('Owner', deal.ownerLabel),
          _kv('Contacts', deal.contacts.isEmpty ? '—' : deal.contactNames),
          if (deal.coldReason != null && deal.coldReason!.isNotEmpty)
            _kv('Cold Reason', deal.coldReason!),
          // "Description" and "Payment Status" rows were removed — neither
          // exists on the Deal API, so both always rendered placeholders.
          (
            'Expected Close',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  close != null ? DateFormatter.displayDate(close) : 'N/A',
                  style: AppTextStyles.bodyMedium,
                ),
                if (remaining != null)
                  Text(
                    '($remaining)',
                    style: AppTextStyles.caption.copyWith(
                      color: remainingColor,
                    ),
                  ),
              ],
            ),
          ),
          // D1–D8 scoring, computed server-side; '—' when unscored.
          (
            'Priority',
            deal.priority == null
                ? Text('—', style: AppTextStyles.bodyMedium)
                : StatusBadge.priority(deal.priority!),
          ),
          _kv('Total Score', deal.totalScore?.toString() ?? '—'),
          _kv('Response Mode', deal.responseMode ?? '—'),
          _kv('Proposal SLA', deal.proposalSla ?? '—'),
          _kv(
            'Proposal SLA Due',
            deal.proposalSlaDueAt == null
                ? '—'
                : DateFormatter.dateTime(deal.proposalSlaDueAt!),
          ),
          _kv(
            'Proposal Status',
            deal.proposalStatus == 'proposal_sent'
                ? 'Proposal Sent${deal.proposalSentAt == null ? '' : ' on ${DateFormatter.displayDate(deal.proposalSentAt!)}'}'
                : 'Not Sent',
          ),
          (
            'Originator',
            deal.originator == null
                ? Text('—', style: AppTextStyles.bodyMedium)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PersonTypeIcon(deal.originator!.type),
                      const SizedBox(width: 6),
                      Text(
                        deal.originator!.name,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
          ),
          // The one field editable straight from this card.
          (
            'Follow-up',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deal.followUpDate == null
                      ? 'Not set'
                      : DateFormatter.displayDate(deal.followUpDate!),
                  style: AppTextStyles.bodyMedium,
                ),
                if (context.can(Perms.dealsManage)) ...[
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _pickFollowUp(context, deal),
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(
                      deal.followUpDate == null ? 'Add follow-up' : 'Follow-up',
                    ),
                  ),
                  if (deal.followUpDate != null)
                    IconButton(
                      tooltip: 'Clear follow-up',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _saveFollowUp(context, deal, null),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    final qualification = QualificationCard(deal: deal);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: context.isWeb
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: info),
                const SizedBox(width: AppSpacing.xl),
                Expanded(flex: 2, child: qualification),
              ],
            )
          : Column(
              children: [
                info,
                const SizedBox(height: AppSpacing.xl),
                qualification,
              ],
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

  Future<void> _pickFollowUp(BuildContext context, Deal deal) async {
    final date = await showDatePicker(
      context: context,
      initialDate: deal.followUpDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    await _saveFollowUp(context, deal, date);
  }

  /// PATCHes only `follow_up_date` ([date] null clears it).
  Future<void> _saveFollowUp(
    BuildContext context,
    Deal deal,
    DateTime? date,
  ) async {
    final bloc = context.read<DealDetailBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final result = await sl<UpdateDealUseCase>()(
      UpdateDealParams(
        id: deal.id,
        followUpDate: date,
        clearFollowUp: date == null,
      ),
    );
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save follow-up: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => bloc.add(DealDetailLoadRequested(deal.id)),
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

  (String, Widget) _kv(String label, String value) => (label, Text(value));
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
    final secondary =
        (title != null && title.isNotEmpty && activity.note.isNotEmpty)
        ? activity.note
        : null;
    // `updatedAt` is DB-server-defaulted on every row at creation (see
    // Base.updated_at), so it's never actually null -- `updatedBy` is the
    // field that only gets set on a real edit (mirrors the Accounts byline
    // at account_detail_page.dart).
    final byline = activity.updatedBy != null
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
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDelete(context),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (secondary != null) ...[
            const SizedBox(height: 4),
            Text(
              secondary,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
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
/// "Priya Shah moved this deal from Evaluation to Proposals".
class _StageMoveContent extends StatelessWidget {
  const _StageMoveContent({required this.entry, required this.state});
  final DealStageHistoryEntry entry;
  final DealDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    // Prefer a name the API supplied; fall back to the stage catalog.
    final toName = entry.toStageName ?? state.stageName(entry.toStageId);
    final fromName = entry.fromStageName ?? state.stageName(entry.fromStageId);
    // Who made the move — `changed_by_name` from the stage-history response,
    // or resolved from the user list by the bloc. Unknown only when neither is
    // available, in which case the sentence drops the actor entirely rather
    // than naming a bare user id.
    final actor = entry.changedByName?.trim();
    final hasActor = actor != null && actor.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              children: [
                if (hasActor)
                  TextSpan(
                    text: actor,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ...entry.fromStageId != null
                    ? [
                        TextSpan(
                          text: hasActor
                              ? ' moved this deal from '
                              : 'Stage moved from ',
                        ),
                        TextSpan(
                          text: fromName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const TextSpan(text: ' to '),
                        TextSpan(
                          text: toName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ]
                    : [
                        TextSpan(
                          text: hasActor
                              ? ' created this deal in '
                              : 'Stage set to ',
                        ),
                        TextSpan(
                          text: toName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
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
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
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

/// Deal → Contacts tab. Lists the deal's linked contacts (name/email/phone,
/// straight off the `contacts` array) and lets you link or unlink them.
///
/// `PATCH /deals/{id}` treats `contact_ids` as a full replacement, so add and
/// remove both send the complete resulting id list, never a delta.
class _ContactsTab extends StatefulWidget {
  const _ContactsTab({required this.deal});
  final Deal deal;

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  bool _busy = false;

  Future<void> _save(List<int> contactIds, String successMessage) async {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<DealDetailBloc>();
    setState(() => _busy = true);
    final result = await sl<UpdateDealUseCase>()(
      UpdateDealParams(id: widget.deal.id, contactIds: contactIds),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update contacts: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        bloc.add(DealDetailLoadRequested(widget.deal.id));
      },
    );
  }

  Future<void> _addContact() async {
    final accountId = int.tryParse(widget.deal.accountId);
    if (accountId == null) return;
    final linkedIds = widget.deal.contactIds.toSet();
    final picked = await showDialog<Contact>(
      context: context,
      builder: (_) =>
          _LinkContactDialog(accountId: accountId, excludedIds: linkedIds),
    );
    if (picked == null || !mounted) return;
    await _save([...linkedIds, picked.id], 'Contact linked to this deal.');
  }

  Future<void> _removeContact(DealContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink contact?'),
        content: Text(
          '${contact.name} will no longer be linked to this deal. '
          'The contact record itself is not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final remaining = widget.deal.contactIds
        .where((id) => id != contact.id)
        .toList();
    await _save(remaining, 'Contact unlinked.');
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.can(Perms.dealsManage);
    final contacts = widget.deal.contacts;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: SectionCard(
        title: contacts.isEmpty ? 'Contacts' : 'Contacts (${contacts.length})',
        trailing: canManage
            ? TextButton.icon(
                onPressed: _busy ? null : _addContact,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1, size: 18),
                label: Text(_busy ? 'Saving...' : 'Add Contact'),
              )
            : null,
        child: contacts.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  canManage
                      ? 'No contacts linked yet. Use “Add Contact” to link '
                            'someone from this account.'
                      : 'No contacts are linked to this deal.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < contacts.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _DealContactRow(
                      contact: contacts[i],
                      canManage: canManage,
                      onRemove: _busy
                          ? null
                          : () => _removeContact(contacts[i]),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Picks a contact from the deal's account to link. Contacts already on the
/// deal are excluded so the same person can't be added twice.
class _LinkContactDialog extends StatefulWidget {
  const _LinkContactDialog({
    required this.accountId,
    required this.excludedIds,
  });
  final int accountId;
  final Set<int> excludedIds;

  @override
  State<_LinkContactDialog> createState() => _LinkContactDialogState();
}

class _LinkContactDialogState extends State<_LinkContactDialog> {
  List<Contact> _options = const [];
  bool _loading = true;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetContactsUseCase>()(
      GetContactsParams(accountId: widget.accountId, limit: 100),
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loading = false),
      (page) => setState(() {
        _options = page.items
            .where((c) => !widget.excludedIds.contains(c.id))
            .toList();
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Link a Contact'),
      content: SizedBox(
        width: 380,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            : _options.isEmpty
            ? Text(
                'Every contact on this account is already linked to the deal. '
                'Add a new contact from the Account page first.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : DropdownButtonFormField<int>(
                initialValue: _selectedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Contact'),
                items: _options
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          c.email == null || c.email!.isEmpty
                              ? c.fullName
                              : '${c.fullName} · ${c.email}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedId = v),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedId == null
              ? null
              : () => Navigator.pop(
                  context,
                  _options.firstWhere((c) => c.id == _selectedId),
                ),
          child: const Text('Link'),
        ),
      ],
    );
  }
}

/// One row in the Contacts tab — name, then tappable email / phone from the
/// `/deals` payload. Either detail may be absent, in which case its line is
/// omitted rather than showing an empty link.
class _DealContactRow extends StatelessWidget {
  const _DealContactRow({
    required this.contact,
    required this.canManage,
    required this.onRemove,
  });
  final DealContact contact;
  final bool canManage;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final display = contact.name.isEmpty ? 'Unnamed contact' : contact.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(name: display, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display,
                  style: AppTextStyles.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (contact.hasEmail) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LinkText(
                          text: contact.email!,
                          email: contact.email,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
                if (contact.hasPhone) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LinkText(
                          text: contact.phone!,
                          phone: contact.phone,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
                // Neither field recorded — say so instead of rendering a bare
                // name with unexplained blank space.
                if (!contact.hasEmail && !contact.hasPhone) ...[
                  const SizedBox(height: 4),
                  Text(
                    'No email or phone on file',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canManage)
            IconButton(
              tooltip: 'Unlink from deal',
              icon: const Icon(Icons.link_off, size: 18),
              color: AppColors.error,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
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

  /// Client-side name filter — the per-deal documents endpoint takes no
  /// `search` param and the list is small, so filter the loaded set (same
  /// approach as the Account Documents tab).
  String _filter = '';

  List<DealDocument> get _filtered {
    final q = _filter.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

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
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not read the selected file.'),
          backgroundColor: AppColors.error,
        ),
      );
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
        messenger.showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${fail.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (doc) {
        messenger.showSnackBar(
          SnackBar(content: Text('“${f.name}” uploaded.')),
        );
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
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Only worth showing once there's something to filter.
            if (!_loading && _error == null && _all.isNotEmpty) ...[
              SizedBox(
                width: 260,
                child: TextField(
                  onChanged: (v) => setState(() => _filter = v),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'Search document name...',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildBody(canManage),
          ],
        ),
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
                Icon(
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
    // Documents exist but the name filter excluded them all.
    final rows = _filtered;
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Text(
          'No documents match “${_filter.trim()}”.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _DealDocumentRow(
            document: rows[i],
            uploaderName: _uploaderName(rows[i].uploadedBy),
            canManage: canManage,
            onView: () => launchWebUrl(_mediaUrl(rows[i].fileUrl)),
            onDelete: () => _delete(rows[i]),
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
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}
