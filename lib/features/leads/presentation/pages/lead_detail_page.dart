import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/widgets/record_export_button.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../../core/widgets/compact_date_range_dialog.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/usecases/export_leads_usecase.dart';
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
              SnackBar(
                content: Text('Lead converted to Account successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/accounts/${state.accountId}');
          }
          if (state is LeadDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
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

    // The Overview/Activity tabs sit above the center column only — the
    // Contact Information and Related Records side panels stay top-aligned
    // with the tab row (matches the mockups).
    final tabbedCenter = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.tab,
            tabAlignment: TabAlignment.start,
            tabs: [
              _iconTab(Icons.dashboard_outlined, 'Overview'),
              _iconTab(Icons.history, 'Activity', count: _activityCount(lead)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _CenterContent(tabController: _tabController, state: state),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(lead: lead),
          const SizedBox(height: AppSpacing.xl),
          ResponsiveBuilder(
            mobile: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tabbedCenter,
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
                Expanded(child: tabbedCenter),
                const SizedBox(width: AppSpacing.xl),
                SizedBox(width: 280, child: _RelatedRecordsCard(lead: lead)),
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
}

int _activityCount(Lead lead) =>
    lead.activityCount ?? (lead.activities?.length ?? 0);

DateTime? _mostRecentActivity(Lead lead) {
  final activities = lead.activities;
  if (activities == null || activities.isEmpty) return null;
  return activities
      .map((a) => a.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}

/// Human duration that stays consistent with "Created … ago": shows hours
/// (and minutes) for young leads rather than rounding down to "0 days".
String _formatDuration(Duration d) {
  if (d.inDays >= 1) {
    final days = d.inDays;
    return '$days day${days == 1 ? '' : 's'}';
  }
  if (d.inHours >= 1) {
    final hours = d.inHours;
    return '$hours hour${hours == 1 ? '' : 's'}';
  }
  final mins = d.inMinutes < 1 ? 1 : d.inMinutes;
  return '$mins minute${mins == 1 ? '' : 's'}';
}

/// "3 days" since the lead was created, or null when the API omitted it.
String? _inSystemLabel(Lead lead) => lead.createdAt == null
    ? null
    : _formatDuration(DateTime.now().difference(lead.createdAt!));

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
    final displayName = contactName.isEmpty ? lead.company : contactName;
    final canManage = context.can(Perms.leadsManage);
    final statusLabel = labelForWireValue(leadStatusLabels, lead.status);
    final mutedLabel = AppTextStyles.labelLarge.copyWith(
      color: AppColors.textSecondary,
    );

    final breadcrumb = Row(
      children: [
        InkWell(
          onTap: () => context.go('/leads'),
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
                Text('Back to Leads', style: mutedLabel),
              ],
            ),
          ),
        ),
        Text(
          '  /  ',
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textMuted),
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: lead.company,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: '  •  $statusLabel', style: mutedLabel),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        if (!context.isMobile)
          Text(
            [
              'LD-${lead.id}',
              if (lead.createdAt != null)
                'Created ${DateFormatter.displayDate(lead.createdAt!)}',
            ].join('  •  '),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            StatusBadge.leadStatus(statusLabel),
            // Mark converted leads so it's clear this prospect is now an
            // account.
            if (lead.isConverted)
              StatusBadge(
                label: 'Account',
                backgroundColor: AppColors.successLight,
                textColor: AppColors.success,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            InitialsAvatar(name: displayName, size: 48),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                displayName,
                style: context.isMobile ? AppTextStyles.h2 : AppTextStyles.h1,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: () => context.read<LeadDetailBloc>().add(
                LeadDetailFavouriteToggled(lead.id, !lead.isFavourite),
              ),
              icon: Icon(
                lead.isFavourite ? Icons.star : Icons.star_border,
                size: 20,
                color: lead.isFavourite
                    ? AppColors.warning
                    : AppColors.textMuted,
              ),
              tooltip: lead.isFavourite
                  ? 'Remove from favourites'
                  : 'Mark as favourite',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${lead.jobTitle ?? ''}${lead.jobTitle != null ? ' at ' : ''}${lead.company}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Owner: ', style: AppTextStyles.bodySmall),
                OwnerChip(name: lead.ownerName),
              ],
            ),
          ],
        ),
      ],
    );

    // Export is read-only, so it sits outside the `canManage` actions —
    // view-only users can download the record too. Edit / Convert / Delete
    // require `leads.access` (manage); Delete lives in the overflow menu.
    final actions = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RecordExportButton(
          tooltip: 'Export this lead to Excel',
          fileName: 'lead_${lead.id}.xlsx',
          successMessage: 'Lead exported.',
          fetch: () => sl<ExportLeadDetailUseCase>()(lead.id),
        ),
        if (canManage) ...[
          OutlinedButton.icon(
            onPressed: () => _editLead(context, lead),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
          if (!lead.isConverted)
            ElevatedButton.icon(
              onPressed: () => _showConvertDialog(context, lead),
              icon: const Icon(Icons.swap_horiz, size: 16),
              label: const Text('Convert to Account'),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
            child: SizedBox(
              height: AppSpacing.buttonHeight - 2,
              width: AppSpacing.buttonHeight - 2,
              child: PopupMenuButton<String>(
                tooltip: 'More actions',
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete(context, lead.id);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    final lastActivity = _mostRecentActivity(lead);
    final followUp = lead.nextFollowUpDate;
    final stats = Wrap(
      spacing: AppSpacing.huge,
      runSpacing: AppSpacing.lg,
      children: [
        MetaStat(
          label: 'Source',
          value: Text(labelForWireValue(leadSourceLabels, lead.source)),
        ),
        MetaStat(
          label: 'Next follow-up',
          value: Text(
            followUp == null ? 'Not set' : DateFormatter.displayDate(followUp),
          ),
        ),
        MetaStat(label: 'Activities', value: Text('${_activityCount(lead)}')),
        MetaStat(
          label: 'Last contact',
          value: Text(
            lastActivity == null
                ? 'Never'
                : DateFormatter.relativeTime(lastActivity),
          ),
        ),
        MetaStat(label: 'In system', value: Text(_inSystemLabel(lead) ?? '—')),
        MetaStat(
          label: 'Last updated',
          value: Text(DateFormatter.displayDate(lead.updatedAt)),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        breadcrumb,
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            context.isMobile ? AppSpacing.lg : AppSpacing.xxl,
          ),
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
              const SizedBox(height: AppSpacing.xl),
              stats,
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editLead(BuildContext context, Lead lead) async {
    final bloc = context.read<LeadDetailBloc>();
    await context.push(
      RoutePaths.editLead.replaceFirst(':id', '${lead.id}'),
      extra: lead,
    );
    // Refresh so edits show without navigating away and back.
    bloc.add(LeadDetailLoadRequested(lead.id));
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
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
              // A long user name in the owner dropdown would otherwise widen
              // the dialog to fit it.
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select an Account Tier:'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedTier,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: leadTierLabels.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedTier = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Select Account Owner:'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int?>(
                      value: selectedOwnerId,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: users
                          .map(
                            (u) => DropdownMenuItem<int?>(
                              value: u.id,
                              child: Text(u.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedOwnerId = v),
                    ),
                  ],
                ),
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
          LeadDetailConvertRequested(
            lead.id,
            tier: selectedTier,
            ownerId: selectedOwnerId,
          ),
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
      child: InfoGrid(
        items: [
          ('Primary Email', LinkText(text: lead.email, email: lead.email)),
          (
            'Phone',
            (lead.phone != null && lead.phone!.isNotEmpty)
                ? LinkText(text: lead.phone!, phone: lead.phone)
                : const Text('Not provided'),
          ),
          if (lead.domain != null)
            (
              'Website',
              LinkText(text: lead.domain!, url: lead.domain, maxLines: 1),
            ),
          // Long profile URLs used to ellipsize into uselessness in this
          // narrow side panel, so show a compact label (scheme/`www.`
          // stripped, tail elided) and keep the full URL in a tooltip.
          if (lead.linkedinUrl != null)
            (
              'LinkedIn',
              Tooltip(
                message: lead.linkedinUrl!,
                child: LinkText(
                  text: _shortLinkLabel(lead.linkedinUrl!),
                  url: lead.linkedinUrl,
                  maxLines: 1,
                ),
              ),
            ),
          (
            'Source',
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(
                label: labelForWireValue(leadSourceLabels, lead.source),
                backgroundColor: AppColors.primaryLight,
                textColor: AppColors.primary,
              ),
            ),
          ),
          (
            'Created',
            Text(
              lead.createdAt != null
                  ? '${DateFormatter.relativeTime(lead.createdAt!)} by ${lead.ownerName ?? 'Unassigned'}'
                  : 'Unknown',
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedRecordsCard extends StatelessWidget {
  const _RelatedRecordsCard({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Related Records',
      child: _DashedBox(
        child: Column(
          children: [
            Icon(
              lead.isConverted
                  ? Icons.check_circle_outline
                  : Icons.account_balance_outlined,
              size: 34,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              lead.isConverted
                  ? 'This lead has already been converted to an account.'
                  : "This lead hasn't been converted to an account yet.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (!lead.isConverted && context.can(Perms.leadsManage)) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () => _HeaderConvertProxy.show(context, lead),
                child: const Text(
                  'Convert to\nAccount',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A dashed-border container used for the "Related Records" empty panel.
class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBoxPainter(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: child),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
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
  bool shouldRepaint(covariant _DashedBoxPainter oldDelegate) => false;
}

/// Compact, readable label for a profile URL: drops the scheme and any
/// leading `www.`, and elides the middle of very long paths so the
/// recognisable head and tail both stay visible in a narrow column.
String _shortLinkLabel(String rawUrl, {int maxLength = 34}) {
  var label = rawUrl.trim().replaceFirst(RegExp(r'^https?://'), '');
  label = label.replaceFirst(RegExp(r'^www\.'), '');
  if (label.endsWith('/')) label = label.substring(0, label.length - 1);
  if (label.length <= maxLength) return label;
  // Keep more of the head than the tail — the domain/handle prefix carries
  // most of the meaning.
  final headLength = maxLength - 9;
  return '${label.substring(0, headLength)}…${label.substring(label.length - 6)}';
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
    final activityCount = _activityCount(lead);
    final inSystemLabel = _inSystemLabel(lead);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!lead.isConverted && context.can(Perms.leadsManage)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.onAccent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to convert?',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.onAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inSystemLabel != null
                            ? 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'} over $inSystemLabel.'
                            : 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'}.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.onAccent.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                // The banner's own "Convert to Account" button was removed —
                // it duplicated the one in the header actions.
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        // Activities / Last contact / In system now live in the header's
        // MetaStat strip.
        SectionCard(
          // No trailing edit icon here — editing is done from the single Edit
          // button in the page header.
          title: 'Initial Notes',
          child: lead.followUpNote != null && lead.followUpNote!.isNotEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Text(
                    lead.followUpNote!,
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : Text(
                  'No initial notes recorded yet.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ],
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

/// Node accent colors per activity type (drives the timeline dots).
const Map<String, Color> _activityColors = {
  'call': Color(0xFF3B82F6),
  'meeting': Color(0xFF8B5CF6),
  'note': Color(0xFF64748B),
  'comment': Color(0xFF06B6D4),
  'follow_up': Color(0xFF10B981),
};

/// `labelForWireValue` returns '' for a null type (auto-logged activities
/// like the favourite toggle's note don't have one) — blank reads as a
/// rendering glitch here, so name it instead.
String _activityTypeLabel(String? type) =>
    type == null ? 'Update' : labelForWireValue(leadActivityTypeLabels, type);

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

  /// Same picker the Leads list uses, rather than Material's
  /// [showDateRangePicker]: one small month, pick start then end in the one
  /// open dialog. The stock picker takes over the window and needed a
  /// ConstrainedBox to be talked back down into something dialog-sized.
  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showCompactDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialStart: widget.state.activityDateFrom,
      initialEnd: widget.state.activityDateTo,
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
    final canManage = context.can(Perms.leadsManage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canManage) ...[
          ElevatedButton.icon(
            onPressed: () => _showLogActivityDialog(context, state.lead.id),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Log Activity'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _filterCard(state),
        const SizedBox(height: AppSpacing.lg),
        if (state.activities.isEmpty)
          _emptyState(context, canManage, state.lead.id)
        else
          _ActivityTimeline(
            leadId: state.lead.id,
            activities: state.activities,
          ),
      ],
    );
  }

  /// The type-filter + date-range card that sits above the timeline.
  Widget _filterCard(LeadDetailLoaded state) {
    final hasRange =
        state.activityDateFrom != null && state.activityDateTo != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: appCardDecoration(),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'FILTER ACTIVITY',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          for (final entry in leadActivityTypeLabels.entries)
            _checkFilter(
              type: entry.key,
              label: entry.value,
              selected: state.activityTypeFilter.contains(entry.key),
              onTap: () => _toggleType(entry.key),
            ),
          OutlinedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: Text(
              hasRange
                  ? '${DateFormatter.shortDate(state.activityDateFrom!)} - ${DateFormatter.shortDate(state.activityDateTo!)}'
                  : 'Date range',
            ),
          ),
          if (state.activityDateFrom != null)
            IconButton(
              tooltip: 'Clear date range',
              onPressed: _clearDateRange,
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  /// One type toggle. Box + type icon + singular label, same as the Accounts
  /// detail page's filter bar — the two used to differ in every one of
  /// those three details.
  Widget _checkFilter({
    required String type,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _activityIcons[type] ?? Icons.circle,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool canManage, int leadId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      decoration: appCardDecoration(),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, size: 44, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No activities logged yet', style: AppTextStyles.h4),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Track your interactions with this lead — calls, meetings, notes, '
            'and follow-ups all in one place.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showLogActivityDialog(context, leadId),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log First Activity'),
            ),
          ],
        ],
      ),
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
                      items: leadActivityTypeLabels.entries
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

/// The Activity tab body — a vertical timeline of logged activities, newest
/// first, with a colored icon node per type connected by a track.
class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.leadId, required this.activities});
  final int leadId;
  final List<LeadActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(activities.length, (i) {
        return _TimelineRow(
          leadId: leadId,
          activity: activities[i],
          isLast: i == activities.length - 1,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.leadId,
    required this.activity,
    required this.isLast,
  });
  final int leadId;
  final LeadActivity activity;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _activityColors[activity.type] ?? AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  _activityIcons[activity.type] ?? Icons.circle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
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
              child: _ActivityRow(leadId: leadId, activity: activity),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.leadId, required this.activity});
  final int leadId;
  final LeadActivity activity;

  @override
  Widget build(BuildContext context) {
    final canManage = context.can(Perms.leadsManage);
    final who = activity.createdByName ?? 'User ${activity.createdBy}';
    // `updatedAt` is DB-server-defaulted on every row at creation (see
    // Base.updated_at), so it's never actually null -- `updatedBy` is the
    // field that only gets set on a real edit (mirrors the Accounts byline
    // at account_detail_page.dart).
    final meta = activity.updatedBy != null
        ? '${DateFormatter.dateTime(activity.createdAt)}, Edited ${DateFormatter.displayDate(activity.updatedAt!)} by ${activity.updatedByName ?? who}'
        : '${DateFormatter.dateTime(activity.createdAt)} by $who';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activityTypeLabel(activity.type),
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (canManage) ...[
                InkWell(
                  onTap: () => _showEditDialog(context),
                  borderRadius: BorderRadius.circular(4),
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
                  borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: AppSpacing.sm),
          Text(activity.note, style: AppTextStyles.bodyMedium),
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
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final noteController = TextEditingController(text: activity.note);
    final bloc = context.read<LeadDetailBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          // Fixed width for the same reason as the Log Activity dialog: an
          // existing long note would otherwise set the dialog's width.
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The activity type is fixed once logged — only the note can be
                // edited. Show the type read-only for context.
                Text(
                  _activityTypeLabel(activity.type),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Note'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  autofocus: true,
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
                // Send only the note — the type is immutable on edit.
                bloc.add(
                  LeadDetailActivityUpdateRequested(
                    leadId,
                    activity.id,
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
