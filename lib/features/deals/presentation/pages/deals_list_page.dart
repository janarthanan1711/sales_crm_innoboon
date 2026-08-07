import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/file_download/file_download.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/usecases/get_deal_stages_usecase.dart';
import '../../domain/usecases/export_deals_usecase.dart';
import '../bloc/deals_list_bloc.dart';
import '../widgets/kanban_board.dart';
import 'create_deal_page.dart';

/// The tiers shown as filter checkboxes (order matches the figma).
const List<String> _kTierOrder = ['diamond', 'gold', 'silver', 'bronze'];

/// Client-side sort options for the "Expected Close" dropdown.
enum _CloseSort { none, soonest, latest }

class DealsListPage extends StatelessWidget {
  const DealsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DealsListBloc>()..add(const DealsListLoadRequested()),
      child: const _DealsListView(),
    );
  }
}

class _DealsListView extends StatefulWidget {
  const _DealsListView();

  @override
  State<_DealsListView> createState() => _DealsListViewState();
}

class _DealsListViewState extends State<_DealsListView> {
  bool _isKanbanView = true;
  List<OwnerUser> _users = [];
  List<DealStageDef> _stages = [];

  // Client-side filters (owner is server-side via the bloc).
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  final Set<String> _selectedTiers = {..._kTierOrder};
  _CloseSort _closeSort = _CloseSort.none;
  String? _closeLabel;
  String? _ownerName;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadStages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final result = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (u) => setState(() => _users = u));
  }

  Future<void> _loadStages() async {
    final result = await sl<GetDealStagesUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (s) => setState(() => _stages = s));
  }

  /// Applies the client-side search / tier / expected-close-sort over the
  /// deals already loaded from the API. (Owner is filtered server-side.)
  List<Deal> _applyClientFilters(List<Deal> deals) {
    var out = deals;
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out
          .where(
            (d) =>
                d.name.toLowerCase().contains(q) ||
                d.accountName.toLowerCase().contains(q),
          )
          .toList();
    }
    // Only filter when a strict subset of tiers is selected — all (or none)
    // selected means "no tier filter", so nothing is hidden unexpectedly.
    if (_selectedTiers.isNotEmpty &&
        _selectedTiers.length < _kTierOrder.length) {
      out = out
          .where((d) => _selectedTiers.contains(d.tier.toLowerCase()))
          .toList();
    }
    if (_closeSort != _CloseSort.none) {
      out = [...out]
        ..sort((a, b) {
          final ad = a.expectedCloseDate;
          final bd = b.expectedCloseDate;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1; // nulls last
          if (bd == null) return -1;
          return _closeSort == _CloseSort.soonest
              ? ad.compareTo(bd)
              : bd.compareTo(ad);
        });
    }
    return out;
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
            _buildHeader(context),
            const SizedBox(height: AppSpacing.lg),
            _buildFilters(context),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocConsumer<DealsListBloc, DealsListState>(
                listener: (context, state) {
                  if (state is DealsListLoaded && state.actionError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.actionError!),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is DealsListLoading) {
                    return const AppLoadingIndicator(
                      message: 'Loading deals...',
                    );
                  }
                  if (state is DealsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<DealsListBloc>().add(
                        const DealsListLoadRequested(),
                      ),
                    );
                  }
                  if (state is DealsListLoaded) {
                    final deals = _applyClientFilters(state.deals);
                    if (deals.isEmpty) {
                      return const EmptyState(
                        icon: Icons.monetization_on_outlined,
                        title: 'No deals found',
                        subtitle: 'Adjust your filters or add a new deal',
                      );
                    }
                    return _isKanbanView
                        ? KanbanBoard(
                            deals: deals,
                            stages: state.stages.isNotEmpty
                                ? state.stages
                                : _stages,
                            canManage: context.can(Perms.dealsManage),
                          )
                        : _DealsTable(deals: deals);
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

  void _openCreateDealDialog(BuildContext context) {
    final bloc = context.read<DealsListBloc>();
    showDialog(context: context, builder: (_) => const CreateDealDialog()).then(
      (result) {
        if (result != null) bloc.add(const DealsListLoadRequested());
      },
    );
  }

  /// Exports the currently-filtered deals as an `.xlsx` via `GET /deals?to_export=true`.
  /// The export API supports `owner_id`/`search`/`tier`/`stage_id`. Owner and
  /// stage come from the bloc's active filter; `tier` is repeatable, so the
  /// whole checkbox selection goes across — the spreadsheet matches the screen
  /// even for a two- or three-tier selection, which previously exported
  /// unfiltered.
  Future<void> _onExport(BuildContext context) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<DealsListBloc>();
    setState(() => _exporting = true);

    // All (or none) ticked means "no tier filter" — same rule the on-screen
    // list uses in _applyClientFilters, so the two can't disagree.
    final tiers =
        _selectedTiers.isEmpty || _selectedTiers.length == _kTierOrder.length
        ? null
        : _kTierOrder.where(_selectedTiers.contains).toList();
    final search = _search.trim().isEmpty ? null : _search.trim();
    final blocState = bloc.state;
    final ownerId = blocState is DealsListLoaded
        ? blocState.ownerIdFilter
        : null;
    final stageId = blocState is DealsListLoaded
        ? blocState.stageIdFilter
        : null;

    final result = await sl<ExportDealsUseCase>()(
      ExportDealsParams(
        ownerId: ownerId,
        stageId: stageId,
        tiers: tiers,
        search: search,
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
        await downloadBytes(bytes, 'deals.xlsx');
        messenger.showSnackBar(
          const SnackBar(content: Text('Deals exported.')),
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
          : const Icon(Icons.file_download_outlined, size: 16),
      label: Text(_exporting ? 'Exporting...' : 'Export'),
    );
  }

  String _compactINR(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(2)} L';
    return CurrencyFormatter.formatINR(v);
  }

  /// The "Total Pipeline Value" figure — sum of the currently-shown deals.
  Widget _pipelineValue(BuildContext context) {
    return BlocBuilder<DealsListBloc, DealsListState>(
      builder: (context, state) {
        final deals = state is DealsListLoaded
            ? _applyClientFilters(state.deals)
            : const <Deal>[];
        final total = deals.fold<double>(0, (s, d) => s + d.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total Pipeline Value',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _compactINR(total),
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canManage = context.can(Perms.dealsManage);
    final title = Row(
      children: [
        Text('Deals', style: AppTextStyles.h1),
        const SizedBox(width: AppSpacing.lg),
        _ViewToggle(
          isBoard: _isKanbanView,
          onChanged: (b) => setState(() => _isKanbanView = b),
        ),
      ],
    );

    final actions = [
      _pipelineValue(context),
      const SizedBox(width: AppSpacing.lg),
      _exportButton(context),
      if (canManage) ...[
        const SizedBox(width: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: () => _openCreateDealDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Deal'),
        ),
      ],
    ];

    if (context.isMobile) {
      // Keep every control within the narrow width: title + toggle share a row
      // via a Spacer, the pipeline figure sits on its own line, and the two
      // action buttons split the width with Expanded. Previously these were in
      // fixed Rows that overflowed and clipped the toggle/buttons off-screen —
      // which silently swallowed their taps.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Deals', style: AppTextStyles.h1),
              const Spacer(),
              _ViewToggle(
                isBoard: _isKanbanView,
                onChanged: (b) => setState(() => _isKanbanView = b),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: _pipelineValue(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _exportButton(context)),
              if (canManage) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateDealDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Deal'),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return Row(children: [title, const Spacer(), ...actions]);
  }

  Widget _buildFilters(BuildContext context) {
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search deals, accounts...',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FilterDropdown(
          label: 'Owner',
          icon: Icons.person_outline,
          selected: _ownerName,
          options: ['All', ..._users.map((u) => u.displayName)],
          onSelected: (v) => _onOwnerSelected(context, v),
        ),
        const SizedBox(width: AppSpacing.sm),
        _FilterDropdown(
          label: 'Expected Close',
          icon: Icons.calendar_today_outlined,
          selected: _closeLabel,
          options: const ['Soonest first', 'Latest first', 'Clear'],
          onSelected: _onCloseSelected,
        ),
        const SizedBox(width: AppSpacing.md),
        Container(width: 1, height: 24, color: AppColors.border),
        const SizedBox(width: AppSpacing.md),
        Text('Tier:', style: AppTextStyles.labelMedium),
        const SizedBox(width: AppSpacing.sm),
        ..._kTierOrder.map(_tierCheck),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: controls,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Icon + label to match the Leads/Accounts filter bars — as a bare
        // text button this read as body copy and was easy to miss.
        TextButton.icon(
          onPressed: _clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
          label: const Text('Clear Filters'),
        ),
      ],
    );
  }

  Widget _tierCheck(String tier) {
    final selected = _selectedTiers.contains(tier);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: () => setState(() {
          if (selected) {
            _selectedTiers.remove(tier);
          } else {
            _selectedTiers.add(tier);
          }
        }),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: selected,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedTiers.add(tier);
                  } else {
                    _selectedTiers.remove(tier);
                  }
                }),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${tier[0].toUpperCase()}${tier.substring(1)}',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  void _onOwnerSelected(BuildContext context, String v) {
    final bloc = context.read<DealsListBloc>();
    if (v == 'All') {
      setState(() => _ownerName = null);
      bloc.add(const DealsListFilterChanged(clearOwner: true));
      return;
    }
    final match = _users.where((u) => u.displayName == v);
    if (match.isNotEmpty) {
      setState(() => _ownerName = v);
      bloc.add(DealsListFilterChanged(ownerId: match.first.id));
    }
  }

  void _onCloseSelected(String v) {
    setState(() {
      switch (v) {
        case 'Soonest first':
          _closeSort = _CloseSort.soonest;
          _closeLabel = 'Soonest first';
        case 'Latest first':
          _closeSort = _CloseSort.latest;
          _closeLabel = 'Latest first';
        default:
          _closeSort = _CloseSort.none;
          _closeLabel = null;
      }
    });
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _selectedTiers
        ..clear()
        ..addAll(_kTierOrder);
      _closeSort = _CloseSort.none;
      _closeLabel = null;
      _ownerName = null;
    });
    context.read<DealsListBloc>().add(
      const DealsListFilterChanged(clearOwner: true, clearStage: true),
    );
  }
}

/// Segmented "Board / List" view switcher.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.isBoard, required this.onChanged});
  final bool isBoard;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            'Board',
            Icons.view_kanban_outlined,
            isBoard,
            () => onChanged(true),
          ),
          _segment(
            'List',
            Icons.view_list_outlined,
            !isBoard,
            () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: active ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealsTable extends StatelessWidget {
  const _DealsTable({required this.deals});
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    final table = Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
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
                _header('DEAL NAME', flex: 3),
                _header('ACCOUNT', flex: 2),
                _header('STAGE', flex: 2),
                _header('VALUE', flex: 1),
                _header('OWNER', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: deals.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _DealRow(deal: deals[index]),
            ),
          ),
        ],
      ),
    );

    if (context.isMobile) {
      // A fixed (tight) width — NOT just a minWidth — so the table's Row-based
      // header/rows get a bounded width for their Expanded children. Inside a
      // horizontal scroll view the max width is unbounded, and ConstrainedBox
      // with only minWidth leaves it unbounded, which fails Expanded's layout.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 800, child: table),
      );
    }
    return table;
  }

  Widget _header(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(label, style: AppTextStyles.tableHeader),
    );
  }
}

class _DealRow extends StatefulWidget {
  const _DealRow({required this.deal});
  final Deal deal;

  @override
  State<_DealRow> createState() => _DealRowState();
}

class _DealRowState extends State<_DealRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/deals/${widget.deal.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          color: _isHovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  widget.deal.name,
                  style: AppTextStyles.tableCellLink,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.deal.accountName,
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.deal.stageLabel,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  CurrencyFormatter.formatINR(widget.deal.value),
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(flex: 2, child: OwnerChip(name: widget.deal.ownerLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

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
      itemBuilder: (context) => options
          .map(
            (option) => PopupMenuItem(
              value: option,
              child: Row(
                children: [
                  Expanded(child: Text(option)),
                  if (option == selected)
                    const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          )
          .toList(),
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
                size: 15,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
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
