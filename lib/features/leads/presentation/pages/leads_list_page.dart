import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/file_download/file_download.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
import '../../domain/entities/lead_import_result.dart';
import '../../domain/usecases/import_leads_usecase.dart';
import '../../domain/usecases/download_import_template_usecase.dart';
import '../../domain/usecases/export_leads_usecase.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
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

class _LeadsListView extends StatefulWidget {
  const _LeadsListView();

  @override
  State<_LeadsListView> createState() => _LeadsListViewState();
}

class _LeadsListViewState extends State<_LeadsListView> {
  final _searchController = TextEditingController();

  String? _statusFilter;
  String? _sourceFilter;
  int? _ownerIdFilter;
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Exports the currently-filtered leads as an `.xlsx` via
  /// `GET /leads?to_export=true`. Owner is role-scoped server-side, but the
  /// owner filter is still forwarded so the file matches the on-screen list.
  Future<void> _onExport(BuildContext context) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);

    final search = _searchController.text.trim();
    final result = await sl<ExportLeadsUseCase>()(
      ExportLeadsParams(
        ownerId: _ownerIdFilter,
        source: _sourceFilter,
        status: _statusFilter,
        search: search.isEmpty ? null : search,
      ),
    );
    if (!mounted) return;
    setState(() => _exporting = false);

    await result.fold(
      (f) async => messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (bytes) async {
        await downloadBytes(bytes, 'leads.xlsx');
        messenger.showSnackBar(
          const SnackBar(content: Text('Leads exported.')),
        );
      },
    );
  }

  Widget _exportButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _exporting ? null : () => _onExport(context),
      icon: _exporting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined, size: 18),
      label: Text(_exporting ? 'Exporting...' : 'Export'),
    );
  }

  void _applyFilters(BuildContext context) {
    context.read<LeadsListBloc>().add(
      LeadsListFilterChanged(
        status: _statusFilter,
        source: _sourceFilter,
        ownerId: _ownerIdFilter,
      ),
    );
  }

  void _clearFilters(BuildContext context) {
    _searchController.clear();
    setState(() {
      _statusFilter = null;
      _sourceFilter = null;
      _ownerIdFilter = null;
    });
    context.read<LeadsListBloc>().add(const LeadsListCleared());
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
                        actionLabel: context.can(Perms.leadsManage)
                            ? '+ Add New Lead'
                            : null,
                        onAction: context.can(Perms.leadsManage)
                            ? () => context.go(RoutePaths.createLead)
                            : null,
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
    final title = Column(
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
    );

    // Create/manage actions are gated on `leads.access` (manage). Users
    // with only `leads.view_all` see the list read-only.
    final canManage = context.can(Perms.leadsManage);
    final importButton = OutlinedButton.icon(
      onPressed: () {
        final bloc = context.read<LeadsListBloc>();
        showDialog(
          context: context,
          builder: (_) => _ImportLeadsDialog(listBloc: bloc),
        );
      },
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Import Leads'),
    );
    final newLeadButton = ElevatedButton.icon(
      onPressed: () => context.go(RoutePaths.createLead),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('New Lead'),
    );

    // On phones, stack the actions under the title so the buttons don't
    // overflow the row; on wider screens keep them inline on the right.
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          Row(children: [Expanded(child: _exportButton(context))]),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: importButton),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: newLeadButton),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        _exportButton(context),
        if (canManage) ...[
          const SizedBox(width: AppSpacing.sm),
          importButton,
          const SizedBox(width: AppSpacing.sm),
          newLeadButton,
        ],
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
              controller: _searchController,
              hintText: 'Search leads...',
              onChanged: (query) {
                context.read<LeadsListBloc>().add(
                  LeadsListSearchChanged(query),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _OwnerFilterDropdown(
            selectedId: _ownerIdFilter,
            onSelected: (ownerId) {
              setState(() => _ownerIdFilter = ownerId);
              _applyFilters(context);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Source',
            icon: Icons.source_outlined,
            selected: _sourceFilter == null
                ? null
                : labelForWireValue(leadSourceLabels, _sourceFilter!),
            options: ['All', ...AppConstants.leadSources],
            onSelected: (value) {
              setState(() {
                _sourceFilter = value == 'All'
                    ? null
                    : wireValueForLabel(leadSourceLabels, value);
              });
              _applyFilters(context);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Status',
            icon: Icons.circle_outlined,
            selected: _statusFilter == null
                ? null
                : labelForWireValue(leadStatusLabels, _statusFilter!),
            options: ['All', ...AppConstants.leadStatuses],
            onSelected: (value) {
              setState(() {
                _statusFilter = value == 'All'
                    ? null
                    : wireValueForLabel(leadStatusLabels, value);
              });
              _applyFilters(context);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => _clearFilters(context),
            icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// ─── Web/Tablet: Data Table ─────────────────────────────
const double _kCheckboxColWidth = 44;
const double _kActionsColWidth = 56;

class _WebLeadsTable extends StatefulWidget {
  const _WebLeadsTable({required this.leads, required this.total});
  final List<Lead> leads;
  final int total;

  @override
  State<_WebLeadsTable> createState() => _WebLeadsTableState();
}

class _WebLeadsTableState extends State<_WebLeadsTable> {
  final Set<int> _selectedIds = {};

  void _toggleSelected(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(bool? selectAll) {
    setState(() {
      if (selectAll == true) {
        _selectedIds.addAll(widget.leads.map((lead) => lead.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leads = widget.leads;
    final allSelected =
        leads.isNotEmpty &&
        leads.every((lead) => _selectedIds.contains(lead.id));

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
                SizedBox(
                  width: _kCheckboxColWidth,
                  child: Checkbox(
                    value: allSelected,
                    onChanged: _toggleSelectAll,
                  ),
                ),
                _tableHeader('LEAD NAME', flex: 3),
                _tableHeader('COMPANY', flex: 2),
                _tableHeader('CONTACT', flex: 3),
                _tableHeader('SOURCE', flex: 1),
                _tableHeader('STATUS', flex: 2),
                _tableHeader('OWNER', flex: 2),
                _tableHeader('LAST ACTIVITY', flex: 2),
                SizedBox(
                  width: _kActionsColWidth,
                  child: Text(
                    'ACTION',
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.center,
                  ),
                ),
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
                return _LeadTableRow(
                  lead: lead,
                  isSelected: _selectedIds.contains(lead.id),
                  onSelectToggle: () => _toggleSelected(lead.id),
                );
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
                  'Showing ${leads.length} of ${widget.total} leads',
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
  const _LeadTableRow({
    required this.lead,
    required this.isSelected,
    required this.onSelectToggle,
  });
  final Lead lead;
  final bool isSelected;
  final VoidCallback onSelectToggle;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _kCheckboxColWidth,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onSelectToggle(),
                ),
              ),
              // Lead Name
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    InitialsAvatar(
                      name: contactName.isEmpty ? lead.firstName : contactName,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contactName,
                            style: AppTextStyles.tableCellLink,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (lead.jobTitle != null &&
                              lead.jobTitle!.isNotEmpty)
                            Text(
                              lead.jobTitle!,
                              style: AppTextStyles.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Company
              Expanded(
                flex: 2,
                child: Text(
                  lead.company,
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Contact
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ContactLine(
                      icon: Icons.email_outlined,
                      value: lead.email,
                      missingLabel: 'Missing Email',
                    ),
                    const SizedBox(height: 2),
                    _ContactLine(
                      icon: Icons.phone_outlined,
                      value: lead.phone,
                      missingLabel: 'Missing Phone',
                    ),
                  ],
                ),
              ),
              // Source
              Expanded(
                flex: 1,
                child: Text(
                  labelForWireValue(leadSourceLabels, lead.source),
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status — left-aligned so the badge background hugs the text
              // (a static, content-sized width) instead of filling the column.
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge.leadStatus(
                    labelForWireValue(leadStatusLabels, lead.status),
                  ),
                ),
              ),
              // Owner
              Expanded(
                flex: 2,
                child: Text(
                  lead.ownerName ?? 'Unassigned',
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Last Activity
              Expanded(
                flex: 2,
                child: Text(
                  DateFormatter.shortDate(lead.updatedAt),
                  style: AppTextStyles.tableCell,
                ),
              ),
              // Actions
              SizedBox(
                width: _kActionsColWidth,
                child: IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'View lead',
                  onPressed: () => context.go('/leads/${lead.id}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single row inside the Contact cell: shows an icon + value, or a
/// red "Missing X" warning when the value is absent.
class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.value,
    required this.missingLabel,
  });

  final IconData icon;
  final String? value;
  final String missingLabel;

  @override
  Widget build(BuildContext context) {
    final isMissing = value == null || value!.isEmpty;
    if (isMissing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            missingLabel,
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value!,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    this.selected,
  });

  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final IconData? icon;

  /// The currently-selected option label (null when no filter is applied), so
  /// the control reflects the active choice instead of the static [label].
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      itemBuilder: (context) => options.map((option) {
        final isSel = option == selected;
        return PopupMenuItem(
          value: option,
          child: Row(
            children: [
              Expanded(child: Text(option)),
              if (isSel)
                const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : null,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              selected ?? label,
              style: AppTextStyles.labelMedium.copyWith(
                color: active ? AppColors.primary : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Owner Filter Dropdown ──────────────────────────────
/// Options are loaded from `GET /api/v1/users` rather than a static list.
class _OwnerFilterDropdown extends StatefulWidget {
  const _OwnerFilterDropdown({required this.onSelected, this.selectedId});
  final ValueChanged<int?> onSelected;
  final int? selectedId;

  @override
  State<_OwnerFilterDropdown> createState() => _OwnerFilterDropdownState();
}

class _OwnerFilterDropdownState extends State<_OwnerFilterDropdown> {
  List<OwnerUser> _owners = [];

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    final result = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (owners) => setState(() => _owners = owners));
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.selectedId;
    final matches = _owners.where((o) => o.id == selectedId).toList();
    final active = selectedId != null && matches.isNotEmpty;
    final display = active ? matches.first.displayName : 'Owner';
    // Owner ids are positive; use -1 as the "All" sentinel so the menu item
    // has a non-null value (a null-valued PopupMenuItem never fires
    // onSelected — Flutter treats it as a dismissal).
    return PopupMenuButton<int>(
      onSelected: (v) => widget.onSelected(v == -1 ? null : v),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: -1,
          child: Row(
            children: [
              const Expanded(child: Text('All')),
              if (selectedId == null)
                const Icon(Icons.check, size: 16, color: AppColors.primary),
            ],
          ),
        ),
        ..._owners.map(
          (owner) => PopupMenuItem<int>(
            value: owner.id,
            child: Row(
              children: [
                Expanded(child: Text(owner.displayName)),
                if (owner.id == selectedId)
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryLight : null,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              display,
              style: AppTextStyles.labelMedium.copyWith(
                color: active ? AppColors.primary : null,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Import Leads Dialog ────────────────────────────────
const List<String> _kImportAllowedExtensions = ['csv', 'xlsx'];

class _ImportLeadsDialog extends StatefulWidget {
  const _ImportLeadsDialog({required this.listBloc});

  /// The list bloc from the page, so a successful import can refresh the
  /// leads table (the dialog is shown outside that bloc's provider subtree).
  final LeadsListBloc listBloc;

  @override
  State<_ImportLeadsDialog> createState() => _ImportLeadsDialogState();
}

class _ImportLeadsDialogState extends State<_ImportLeadsDialog> {
  PlatformFile? _pickedFile;
  bool _picking = false;
  bool _importing = false;
  String? _downloadingFormat;

  Future<void> _pickFile() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _kImportAllowedExtensions,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _pickedFile = result.files.first);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _downloadTemplate(String format) async {
    setState(() => _downloadingFormat = format);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await sl<DownloadImportTemplateUseCase>()(format: format);
      if (!mounted) return;
      await result.fold(
        (f) async => messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to download template: ${f.message}'),
            backgroundColor: AppColors.error,
          ),
        ),
        (bytes) async => downloadBytes(bytes, 'lead_import_template.$format'),
      );
    } finally {
      if (mounted) setState(() => _downloadingFormat = null);
    }
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return;
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final result = await sl<ImportLeadsUseCase>()(
      ImportLeadsParams(bytes: file.bytes!, filename: file.name),
    );
    if (!mounted) return;
    setState(() => _importing = false);

    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (summary) {
        // Refresh the table so newly-created leads appear.
        widget.listBloc.add(const LeadsListLoadRequested());
        navigator.pop();
        if (summary.hasErrors) {
          showDialog<void>(
            context: navigator.context,
            builder: (_) => _ImportResultDialog(result: summary),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Imported ${summary.created} lead(s) successfully.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Import Leads')),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload File', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: _picking ? null : _pickFile,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: _pickedFile == null
                    ? Column(
                        children: [
                          const Icon(
                            Icons.upload_file_outlined,
                            size: 28,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _picking
                                ? 'Opening file picker...'
                                : 'Click to browse for a file',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile!.name,
                                  style: AppTextStyles.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatSize(_pickedFile!.size),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Remove file',
                            onPressed: () => setState(() => _pickedFile = null),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Only .csv and .xlsx files are supported. Columns must match '
              'the template.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Need a starting point? Download a template with '
                          'the exact columns and an example row.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _downloadingFormat == null
                            ? () => _downloadTemplate('xlsx')
                            : null,
                        icon: _downloadingFormat == 'xlsx'
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.grid_on, size: 16),
                        label: const Text('Excel (.xlsx)'),
                      ),
                      TextButton.icon(
                        onPressed: _downloadingFormat == null
                            ? () => _downloadTemplate('csv')
                            : null,
                        icon: _downloadingFormat == 'csv'
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.description_outlined, size: 16),
                        label: const Text('CSV (.csv)'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_pickedFile == null || _importing) ? null : _upload,
          child: _importing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Upload'),
        ),
      ],
    );
  }
}

/// Shown after an import that had one or more per-row failures — lists which
/// spreadsheet rows were skipped and why (the created rows still went in).
class _ImportResultDialog extends StatelessWidget {
  const _ImportResultDialog({required this.result});
  final LeadImportResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Completed'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${result.created} lead(s) created',
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${result.errors.length} row(s) skipped',
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: result.errors
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            'Row ${e.row}: ${e.error}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
