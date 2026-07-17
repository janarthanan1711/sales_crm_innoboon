import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../bloc/leads_list_bloc.dart';

class LeadsListPage extends StatelessWidget {
  const LeadsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LeadsListBloc>()..add(const LeadsListLoadRequested()),
      child: const _LeadsListView(),
    );
  }
}

class _LeadsListView extends StatelessWidget {
  const _LeadsListView();

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
            // ── Header ─────────────────────
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),

            // ── Filters ────────────────────
            _buildFilters(context),
            const SizedBox(height: AppSpacing.lg),

            // ── Content ────────────────────
            Expanded(
              child: BlocBuilder<LeadsListBloc, LeadsListState>(
                builder: (context, state) {
                  if (state is LeadsListLoading) {
                    return const AppLoadingIndicator(
                      message: 'Loading leads...',
                    );
                  }
                  if (state is LeadsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<LeadsListBloc>().add(
                        const LeadsListLoadRequested(),
                      ),
                    );
                  }
                  if (state is LeadsListLoaded) {
                    if (state.leads.isEmpty) {
                      return EmptyState(
                        icon: Icons.people_outline,
                        title: 'No leads found',
                        subtitle: 'Create your first lead to get started',
                        actionLabel: '+ Add New Lead',
                        onAction: () => context.go(RoutePaths.createLead),
                      );
                    }
                    return ResponsiveBuilder(
                      mobile: _MobileLeadsList(leads: state.leads),
                      web: _WebLeadsTable(
                        leads: state.leads,
                        total: state.total,
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leads', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                'Manage and qualify your sales leads',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => context.go(RoutePaths.createLead),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Lead'),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: context.isMobile ? 200 : 280,
            child: AppSearchField(
              hintText: 'Search leads...',
              onChanged: (query) {
                context.read<LeadsListBloc>().add(
                  LeadsListSearchChanged(query),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Status',
            icon: Icons.circle_outlined,
            options: ['All', ...AppConstants.leadStatuses],
            onSelected: (value) {
              context.read<LeadsListBloc>().add(
                LeadsListFilterChanged(
                  status: value == 'All'
                      ? null
                      : wireValueForLabel(leadStatusLabels, value),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Source',
            icon: Icons.source_outlined,
            options: ['All', ...AppConstants.leadSources],
            onSelected: (value) {
              context.read<LeadsListBloc>().add(
                LeadsListFilterChanged(
                  source: value == 'All'
                      ? null
                      : wireValueForLabel(leadSourceLabels, value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ─── Web/Tablet: Data Table ─────────────────────────────
class _WebLeadsTable extends StatelessWidget {
  const _WebLeadsTable({required this.leads, required this.total});
  final List<Lead> leads;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _tableHeader('COMPANY', flex: 3),
                _tableHeader('CONTACT', flex: 3),
                _tableHeader('SOURCE', flex: 2),
                _tableHeader('STATUS', flex: 2),
                _tableHeader('OWNER', flex: 2),
                _tableHeader('UPDATED', flex: 2),
              ],
            ),
          ),
          // Table rows
          Expanded(
            child: ListView.separated(
              itemCount: leads.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lead = leads[index];
                return _LeadTableRow(lead: lead);
              },
            ),
          ),
          // Pagination footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${leads.length} of $total leads',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label, style: AppTextStyles.tableHeader),
    );
  }
}

class _LeadTableRow extends StatefulWidget {
  const _LeadTableRow({required this.lead});
  final Lead lead;

  @override
  State<_LeadTableRow> createState() => _LeadTableRowState();
}

class _LeadTableRowState extends State<_LeadTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    final contactName = [
      lead.firstName,
      lead.lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/leads/${lead.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: _isHovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              // Company
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    InitialsAvatar(name: lead.company, size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        lead.company,
                        style: AppTextStyles.tableCellLink,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Contact
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: AppTextStyles.tableCell,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      lead.email,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Source
              Expanded(
                flex: 2,
                child: Text(
                  labelForWireValue(leadSourceLabels, lead.source),
                  style: AppTextStyles.tableCell,
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: StatusBadge.leadStatus(
                  labelForWireValue(leadStatusLabels, lead.status),
                ),
              ),
              // Owner
              Expanded(flex: 2, child: OwnerChip(name: lead.ownerName)),
              // Updated
              Expanded(
                flex: 2,
                child: Text(
                  DateFormatter.shortDate(lead.updatedAt),
                  style: AppTextStyles.tableCell,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── Mobile: Card List ──────────────────────────────────
class _MobileLeadsList extends StatelessWidget {
  const _MobileLeadsList({required this.leads});
  final List<Lead> leads;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: leads.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final lead = leads[index];
        return _LeadCard(lead: lead);
      },
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final contactName = [
      lead.firstName,
      lead.lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');

    return Card(
      child: InkWell(
        onTap: () => context.go('/leads/${lead.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: lead.company, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lead.company, style: AppTextStyles.h4),
                        Text(contactName, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  StatusBadge.leadStatus(
                    labelForWireValue(leadStatusLabels, lead.status),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '• ${labelForWireValue(leadSourceLabels, lead.source)}',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.relativeTime(lead.updatedAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lead.email,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OwnerChip(name: lead.ownerName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── Filter Dropdown ────────────────────────────────────
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem(value: option, child: Text(option));
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
