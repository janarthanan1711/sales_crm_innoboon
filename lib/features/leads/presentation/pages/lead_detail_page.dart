import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/lead_detail_bloc.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';

class LeadDetailPage extends StatelessWidget {
  const LeadDetailPage({super.key, required this.leadId});
  final String leadId;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(leadId) ?? 0;
    return BlocProvider(
      create: (_) => sl<LeadDetailBloc>()..add(LeadDetailLoadRequested(id)),
      child: _LeadDetailView(leadId: id),
    );
  }
}

class _LeadDetailView extends StatefulWidget {
  const _LeadDetailView({required this.leadId});
  final int leadId;

  @override
  State<_LeadDetailView> createState() => _LeadDetailViewState();
}

class _LeadDetailViewState extends State<_LeadDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LeadDetailBloc, LeadDetailState>(
        listener: (context, state) {
          if (state is LeadDetailConverted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead converted to Account successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/accounts/${state.accountId}');
          }
          if (state is LeadDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead deleted.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go(RoutePaths.leads);
          }
        },
        builder: (context, state) {
          if (state is LeadDetailLoading || state is LeadDetailInitial) {
            return const AppLoadingIndicator(message: 'Loading lead...');
          }
          if (state is LeadDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<LeadDetailBloc>().add(
                LeadDetailLoadRequested(widget.leadId),
              ),
            );
          }
          if (state is LeadDetailLoaded) {
            return _buildContent(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, LeadDetailLoaded state) {
    final lead = state.lead;
    final padding = context.pagePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(lead: lead),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTextStyles.labelLarge,
              tabAlignment: TabAlignment.start,
              tabs: const [Tab(text: 'Overview'), Tab(text: 'Activity')],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ResponsiveBuilder(
            mobile: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CenterContent(tabController: _tabController, state: state),
                const SizedBox(height: AppSpacing.xl),
                _ContactInfoCard(lead: lead),
                const SizedBox(height: AppSpacing.xl),
                _RelatedRecordsCard(lead: lead),
              ],
            ),
            web: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: _ContactInfoCard(lead: lead)),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: _CenterContent(
                    tabController: _tabController,
                    state: state,
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 280, child: _RelatedRecordsCard(lead: lead)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Switches between Overview/Activity content based on the shared
/// [tabController] — the Contact Information / Related Records side panels
/// stay mounted across both tabs (matches the design mockups), so this is a
/// manual index switch rather than a `TabBarView` (which would need a
/// separately-bounded height for each tab).
class _CenterContent extends StatelessWidget {
  const _CenterContent({required this.tabController, required this.state});
  final TabController tabController;
  final LeadDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        return tabController.index == 0
            ? _OverviewCenter(state: state)
            : _ActivityCenter(state: state);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final contactName = [
      lead.firstName,
      lead.lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => context.go('/leads'),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: AppSpacing.sm),
            InitialsAvatar(name: contactName.isEmpty ? lead.company : contactName, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    children: [
                      Text(contactName.isEmpty ? lead.company : contactName, style: AppTextStyles.h2),
                      StatusBadge.leadStatus(
                        labelForWireValue(leadStatusLabels, lead.status),
                      ),
                    ],
                  ),
                  Text(
                    '${lead.jobTitle ?? ''}${lead.jobTitle != null ? ' at ' : ''}${lead.company}',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // Edit / Convert / Delete require `leads.access` (manage). View-only
        // users (`leads.view_all`) don't see these actions.
        if (context.can(Perms.leadsManage))
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    RoutePaths.editLead.replaceFirst(':id', '${lead.id}'),
                    extra: lead,
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Lead'),
              ),
              if (!lead.isConverted)
                ElevatedButton.icon(
                  onPressed: () => _showConvertDialog(context, lead),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Convert to Account'),
                ),
              OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, lead.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Delete'),
              ),
            ],
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete lead?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LeadDetailBloc>().add(LeadDetailDeleteRequested(id));
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _showConvertDialog(BuildContext context, Lead lead) async {
    String selectedTier = leadTierLabels.keys.first;
    int? selectedOwnerId = lead.ownerId;
    List<OwnerUser> users = [];

    final usersResult = await sl<GetUsersUseCase>()();
    usersResult.fold((_) {}, (u) => users = u);

    if (!context.mounted) return;
    final bloc = context.read<LeadDetailBloc>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Convert to Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select an Account Tier:'),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: selectedTier,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: leadTierLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedTier = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Select Account Owner:'),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<int?>(
                    value: selectedOwnerId,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: users
                        .map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.displayName)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedOwnerId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedOwnerId == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Convert'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        bloc.add(
          LeadDetailConvertRequested(lead.id, tier: selectedTier, ownerId: selectedOwnerId),
        );
      }
    });
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Contact Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Primary Email'),
          _linkText(lead.email),
          const SizedBox(height: AppSpacing.md),
          _label('Phone'),
          Text(lead.phone ?? 'Not provided', style: AppTextStyles.bodyMedium),
          const Divider(height: AppSpacing.xl * 1.2),
          if (lead.domain != null) ...[
            Row(
              children: [
                const Icon(Icons.language, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(lead.domain!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (lead.linkedinUrl != null)
            Row(
              children: [
                const Icon(Icons.link, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    lead.linkedinUrl!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          const Divider(height: AppSpacing.xl * 1.2),
          _label('Source'),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                labelForWireValue(leadSourceLabels, lead.source),
                style: AppTextStyles.caption,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _label('Owner'),
          Text(lead.ownerName ?? 'Unassigned', style: AppTextStyles.bodyMedium),
          const Divider(height: AppSpacing.xl * 1.2),
          _label('Created'),
          Text(
            lead.createdAt != null
                ? '${DateFormatter.relativeTime(lead.createdAt!)} by System'
                : 'Unknown',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary));

  Widget _linkText(String text) =>
      Text(text, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary));
}

class _RelatedRecordsCard extends StatelessWidget {
  const _RelatedRecordsCard({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Related Records',
      child: Column(
        children: [
          Icon(
            lead.isConverted ? Icons.check_circle_outline : Icons.account_balance_outlined,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            lead.isConverted
                ? 'This lead has already been converted to an account.'
                : "This lead hasn't been converted to an account yet.",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          if (!lead.isConverted && context.can(Perms.leadsManage)) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _HeaderConvertProxy.show(context, lead),
                child: const Text('Convert to Account'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small indirection so the Related Records panel can reuse the exact same
/// convert dialog as the header button without duplicating it.
class _HeaderConvertProxy {
  static Future<void> show(BuildContext context, Lead lead) {
    return _Header(lead: lead)._showConvertDialog(context, lead);
  }
}

class _OverviewCenter extends StatelessWidget {
  const _OverviewCenter({required this.state});
  final LeadDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final lead = state.lead;
    final activityCount = lead.activityCount ?? (lead.activities?.length ?? 0);
    final lastActivity = _mostRecentActivity(lead);
    final daysInSystem = lead.createdAt != null
        ? DateTime.now().difference(lead.createdAt!).inDays
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!lead.isConverted && context.can(Perms.leadsManage))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ready to convert?', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 2),
                      Text(
                        daysInSystem != null
                            ? 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'} over $daysInSystem day${daysInSystem == 1 ? '' : 's'}.'
                            : 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'}.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: () => _HeaderConvertProxy.show(context, lead),
                  child: const Text('Convert to Account'),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: _statTile('$activityCount', 'Activities')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _statTile(
                lastActivity != null ? DateFormatter.relativeTime(lastActivity) : 'Never',
                'Last Contact',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _statTile(
                daysInSystem != null ? '$daysInSystem days' : '—',
                'In System',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Initial Notes',
          child: Text(
            lead.followUpNote ?? 'No initial notes recorded yet.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  DateTime? _mostRecentActivity(Lead lead) {
    final activities = lead.activities;
    if (activities == null || activities.isEmpty) return null;
    return activities.map((a) => a.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

const Map<String, IconData> _activityIcons = {
  'call': Icons.phone,
  'meeting': Icons.groups_outlined,
  'note': Icons.description_outlined,
  'comment': Icons.chat_bubble_outline,
  'follow_up': Icons.event_repeat,
};

class _ActivityCenter extends StatefulWidget {
  const _ActivityCenter({required this.state});
  final LeadDetailLoaded state;

  @override
  State<_ActivityCenter> createState() => _ActivityCenterState();
}

class _ActivityCenterState extends State<_ActivityCenter> {
  void _toggleType(String type) {
    final current = Set<String>.from(widget.state.activityTypeFilter);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    context.read<LeadDetailBloc>().add(
      LeadDetailActivityFilterChanged(
        widget.state.lead.id,
        types: current,
        dateFrom: widget.state.activityDateFrom,
        dateTo: widget.state.activityDateTo,
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          widget.state.activityDateFrom != null && widget.state.activityDateTo != null
          ? DateTimeRange(start: widget.state.activityDateFrom!, end: widget.state.activityDateTo!)
          : null,
    );
    if (range == null || !mounted) return;
    context.read<LeadDetailBloc>().add(
      LeadDetailActivityFilterChanged(
        widget.state.lead.id,
        types: widget.state.activityTypeFilter,
        dateFrom: range.start,
        dateTo: range.end,
      ),
    );
  }

  void _clearDateRange() {
    context.read<LeadDetailBloc>().add(
      LeadDetailActivityFilterChanged(
        widget.state.lead.id,
        types: widget.state.activityTypeFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (context.can(Perms.leadsManage))
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showLogActivityDialog(context, state.lead.id),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log Activity'),
            ),
          ),
        if (context.can(Perms.leadsManage))
          const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final entry in leadActivityTypeLabels.entries)
              FilterChip(
                label: Text('${entry.value}s'),
                selected: state.activityTypeFilter.contains(entry.key),
                onSelected: (_) => _toggleType(entry.key),
              ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.calendar_today_outlined, size: 14),
              label: Text(
                state.activityDateFrom != null && state.activityDateTo != null
                    ? '${DateFormatter.shortDate(state.activityDateFrom!)} - ${DateFormatter.shortDate(state.activityDateTo!)}'
                    : 'Date range',
              ),
            ),
            if (state.activityDateFrom != null)
              IconButton(
                tooltip: 'Clear date range',
                onPressed: _clearDateRange,
                icon: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (state.activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No activities logged yet',
              subtitle: 'Track your interactions with this lead — calls, meetings, notes, and follow-ups all in one place.',
            ),
          )
        else
          Column(
            children: state.activities
                .map((a) => _ActivityRow(leadId: state.lead.id, activity: a))
                .toList(),
          ),
      ],
    );
  }

  void _showLogActivityDialog(BuildContext context, int leadId) {
    String type = leadActivityTypeLabels.keys.first;
    final noteController = TextEditingController();
    final bloc = context.read<LeadDetailBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Log Activity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type'),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: leadActivityTypeLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Note'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: 'What happened?',
                    ),
                  ),
                ],
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
                      LeadDetailActivityLogRequested(
                        leadId,
                        type: type,
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
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.leadId, required this.activity});
  final int leadId;
  final LeadActivity activity;

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      labelForWireValue(leadActivityTypeLabels, activity.type),
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      DateFormatter.dateTime(activity.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
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
          IconButton(
            tooltip: 'Edit',
            onPressed: () => _showEditDialog(context),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final bloc = context.read<LeadDetailBloc>();
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
              bloc.add(LeadDetailActivityDeleteRequested(leadId, activity.id));
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    String type = activity.type;
    final noteController = TextEditingController(text: activity.note);
    final bloc = context.read<LeadDetailBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Edit Activity'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Type'),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: leadActivityTypeLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Note'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
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
                      LeadDetailActivityUpdateRequested(
                        leadId,
                        activity.id,
                        type: type,
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
}
