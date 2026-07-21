import 'dart:convert';
import 'dart:typed_data';
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
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_enums.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    context.read<LeadsListBloc>().add(const LeadsListSearchChanged(''));
    context.read<LeadsListBloc>().add(const LeadsListFilterChanged());
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
        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const _ImportLeadsDialog(),
          ),
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: const Text('Import Leads'),
        ),
        const SizedBox(width: AppSpacing.sm),
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
            onSelected: (ownerId) {
              setState(() => _ownerIdFilter = ownerId);
              _applyFilters(context);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Source',
            icon: Icons.source_outlined,
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
        leads.isNotEmpty && leads.every((lead) => _selectedIds.contains(lead.id));

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
                    'ACTIONS',
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
                          if (lead.jobTitle != null && lead.jobTitle!.isNotEmpty)
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
              // Status
              Expanded(
                flex: 2,
                child: StatusBadge.leadStatus(
                  labelForWireValue(leadStatusLabels, lead.status),
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
          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
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

/// ─── Owner Filter Dropdown ──────────────────────────────
/// Options are loaded from `GET /api/v1/users` rather than a static list.
class _OwnerFilterDropdown extends StatefulWidget {
  const _OwnerFilterDropdown({required this.onSelected});
  final ValueChanged<int?> onSelected;

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
    return PopupMenuButton<int?>(
      onSelected: widget.onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(value: null, child: Text('All')),
        ..._owners.map(
          (owner) => PopupMenuItem<int?>(
            value: owner.id,
            child: Text(owner.displayName),
          ),
        ),
      ],
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
            const Icon(
              Icons.person_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text('Owner', style: AppTextStyles.labelMedium),
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

/// ─── Import Leads Dialog ────────────────────────────────
const List<String> _kImportAllowedExtensions = ['csv', 'xlsx'];

/// Sample CSV columns mirror the Create Lead form fields exactly (see
/// create_lead_page.dart), using the same placeholder values shown as
/// hints there so the two stay recognizably in sync.
const String _kSampleCsvHeader =
    'first_name,last_name,company,company_domain,job_title,linkedin_url,'
    'email,phone,source,status,owner_email,follow_up_note';
const String _kSampleCsvRow =
    'Jane,Doe,Acme Corp,acme.com,VP of Sales,linkedin.com/in/janedoe,'
    'jane.doe@acme.com,+1 (555) 000-0000,Website,Not Contacted,'
    'owner@example.com,Interested in the enterprise plan';

class _ImportLeadsDialog extends StatefulWidget {
  const _ImportLeadsDialog();

  @override
  State<_ImportLeadsDialog> createState() => _ImportLeadsDialogState();
}

class _ImportLeadsDialogState extends State<_ImportLeadsDialog> {
  PlatformFile? _pickedFile;
  bool _picking = false;

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

  Future<void> _downloadSample() async {
    final csv = '$_kSampleCsvHeader\n$_kSampleCsvRow\n';
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await downloadBytes(bytes, 'leads_import_sample.csv');
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
                            onPressed: () =>
                                setState(() => _pickedFile = null),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Only .csv and .xlsx files are supported.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Need a template? Download a sample CSV with a dummy lead.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _downloadSample,
                    child: const Text('Sample Import'),
                  ),
                ],
              ),
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
          onPressed: _pickedFile == null
              ? null
              : () {
                  final messenger = ScaffoldMessenger.of(context);
                  final fileName = _pickedFile!.name;
                  Navigator.pop(context);
                  messenger.showSnackBar(
                    SnackBar(content: Text('$fileName selected.')),
                  );
                },
          child: const Text('Upload'),
        ),
      ],
    );
  }
}
