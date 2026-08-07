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

    // The Overview/Activity tabs sit above the center column only — the
    // Contact Information and Related Records side panels stay top-aligned
    // with the tab row (matches the mockups).
    final tabbedCenter = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Activity'),
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
    final displayName = contactName.isEmpty ? lead.company : contactName;
    final canManage = context.can(Perms.leadsManage);

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.go('/leads'),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to leads',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: AppSpacing.sm),
        InitialsAvatar(name: displayName, size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.sm,
                children: [
                  Text(displayName, style: AppTextStyles.h2),
                  IconButton(
                    onPressed: () => context.read<LeadDetailBloc>().add(
                      LeadDetailFavouriteToggled(lead.id, !lead.isFavourite),
                    ),
                    icon: Icon(
                      lead.isFavourite ? Icons.star : Icons.star_border,
                      size: 18,
                      color: lead.isFavourite
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                    tooltip: lead.isFavourite
                        ? 'Remove from favourites'
                        : 'Mark as favourite',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  StatusBadge.leadStatus(
                    labelForWireValue(leadStatusLabels, lead.status),
                  ),
                  // Mark converted leads so it's clear this prospect is now an
                  // account.
                  if (lead.isConverted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business,
                            size: 13,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Account',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${lead.jobTitle ?? ''}${lead.jobTitle != null ? ' at ' : ''}${lead.company}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [_ownerMeta(), _exportAction()],
                ),
                if (canManage) ...[
                  const SizedBox(height: AppSpacing.md),
                  _actions(context),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.lg),
                _ownerMeta(),
                const SizedBox(width: AppSpacing.lg),
                _exportAction(),
                if (canManage) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _actions(context),
                ],
              ],
            ),
    );
  }

  /// Export is read-only, so it sits outside the `canManage` actions —
  /// view-only users can download the record too.
  ///
  /// The "Tier: —" meta that used to sit beside this was removed: a Lead has
  /// no tier of its own (it's assigned at conversion), so it was always an
  /// em-dash placeholder.
  Widget _exportAction() {
    return RecordExportButton(
      tooltip: 'Export this lead to Excel',
      fileName: 'lead_${lead.id}.xlsx',
      successMessage: 'Lead exported.',
      fetch: () => sl<ExportLeadDetailUseCase>()(lead.id),
    );
  }

  Widget _ownerMeta() {
    final owner = lead.ownerName ?? 'Unassigned';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Owner: ',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (lead.ownerName != null) ...[
          InitialsAvatar(name: owner, size: 22),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(owner, style: AppTextStyles.labelMedium),
      ],
    );
  }

  // Edit / Convert / Delete require `leads.access` (manage). View-only users
  // (`leads.view_all`) don't see these actions. Delete lives in the overflow
  // menu to match the mockup.
  Widget _actions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: () => _editLead(context, lead),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Edit'),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!lead.isConverted)
          ElevatedButton.icon(
            onPressed: () => _showConvertDialog(context, lead),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Convert to Account'),
          ),
        // Only Delete lives in the overflow — the "Edit Lead" item that used
        // to be here duplicated the Edit button beside it.
        PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(context, lead.id);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: AppSpacing.sm),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
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
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Primary Email'),
          _linkText(lead.email),
          const SizedBox(height: AppSpacing.md),
          _label('Phone'),
          (lead.phone != null && lead.phone!.isNotEmpty)
              ? LinkText(text: lead.phone!, phone: lead.phone)
              : Text('Not provided', style: AppTextStyles.bodyMedium),
          const Divider(height: AppSpacing.xl * 1.2),
          if (lead.domain != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.language,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: LinkText(
                    text: lead.domain!,
                    url: lead.domain,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (lead.linkedinUrl != null)
            Row(
              children: [
                const Icon(
                  Icons.link,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                // Long profile URLs used to ellipsize into uselessness in this
                // narrow side panel, so show a compact label (scheme/`www.`
                // stripped, tail elided) and keep the full URL in a tooltip.
                Expanded(
                  child: Tooltip(
                    message: lead.linkedinUrl!,
                    child: LinkText(
                      text: _shortLinkLabel(lead.linkedinUrl!),
                      url: lead.linkedinUrl,
                      maxLines: 1,
                    ),
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

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
  );

  Widget _linkText(String text) => LinkText(text: text, email: text);
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
    final activityCount = lead.activityCount ?? (lead.activities?.length ?? 0);
    final lastActivity = _mostRecentActivity(lead);
    final inSystem = lead.createdAt != null
        ? DateTime.now().difference(lead.createdAt!)
        : null;
    final inSystemLabel = inSystem == null ? null : _formatDuration(inSystem);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!lead.isConverted && context.can(Perms.leadsManage))
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
                const Icon(Icons.lightbulb_outline, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready to convert?',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inSystemLabel != null
                            ? 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'} over $inSystemLabel.'
                            : 'This lead has been contacted $activityCount time${activityCount == 1 ? '' : 's'}.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
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
        Row(
          children: [
            Expanded(child: _statTile('$activityCount', 'Activities')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _statTile(
                lastActivity != null
                    ? DateFormatter.relativeTime(lastActivity)
                    : 'Never',
                'Last Contact',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _statTile(inSystemLabel ?? '—', 'In System')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
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

  Widget _statTile(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
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

/// Node accent colors per activity type (drives the timeline dots).
const Map<String, Color> _activityColors = {
  'call': Color(0xFF3B82F6),
  'meeting': Color(0xFF8B5CF6),
  'note': Color(0xFF64748B),
  'comment': Color(0xFF06B6D4),
  'follow_up': Color(0xFF10B981),
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
      // By default this picker takes over the whole window. Constrain it into
      // a centered dialog-sized card so it reads as a filter popover.
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
          child: child,
        ),
      ),
      initialDateRange:
          widget.state.activityDateFrom != null &&
              widget.state.activityDateTo != null
          ? DateTimeRange(
              start: widget.state.activityDateFrom!,
              end: widget.state.activityDateTo!,
            )
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final entry in leadActivityTypeLabels.entries)
            _checkFilter(
              label: '${entry.value}s',
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

  Widget _checkFilter({
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
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 44,
            color: AppColors.textMuted,
          ),
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
              content: Column(
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
    final meta = activity.updatedAt != null
        ? '${DateFormatter.dateTime(activity.createdAt)}, Edited ${DateFormatter.displayDate(activity.updatedAt!)} by ${activity.updatedByName ?? who}'
        : '${DateFormatter.dateTime(activity.createdAt)} by $who';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelForWireValue(leadActivityTypeLabels, activity.type),
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
                  child: const Padding(
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
                  child: const Padding(
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
    final noteController = TextEditingController(text: activity.note);
    final bloc = context.read<LeadDetailBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The activity type is fixed once logged — only the note can be
              // edited. Show the type read-only for context.
              Text(
                labelForWireValue(leadActivityTypeLabels, activity.type),
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
