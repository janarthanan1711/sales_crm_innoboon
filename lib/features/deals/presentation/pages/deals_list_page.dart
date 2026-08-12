import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/formatters.dart' hide CurrencyFormatter;
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
import '../../../../core/widgets/compact_date_range_dialog.dart';
import '../bloc/deals_list_bloc.dart';
import '../widgets/kanban_board.dart';
import 'create_deal_page.dart';

/// The tiers shown as filter checkboxes (order matches the figma).
const List<String> _kTierOrder = ['diamond', 'gold', 'silver', 'bronze'];

/// Client-side sort options for the "Expected Close" dropdown.
enum _CloseSort { none, soonest, latest }

class DealsListPage extends StatelessWidget {
  /// Drill-down entry point from a dashboard tile tap (Deals in Pipeline /
  /// Deals Closed) — all optional, defaulting to the plain "Deals" list.
  /// `stageState`/`dateField`/`dateFrom`/`dateTo` mirror the `GET /deals`
  /// query params (API doc §6.3); `title` overrides the page heading so the
  /// drilled-down list reads as "Deals in Pipeline" rather than "Deals".
  const DealsListPage({
    super.key,
    this.title,
    this.stageState,
    this.dateField,
    this.dateFrom,
    this.dateTo,
  });

  final String? title;
  final String? stageState;
  final String? dateField;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DealsListBloc(
        getDealsUseCase: sl(),
        getDealStagesUseCase: sl(),
        updateDealStageUseCase: sl(),
        getAccountsUseCase: sl(),
        getUsersUseCase: sl(),
        stageState: stageState,
        dateField: dateField,
        dateFrom: dateFrom,
        dateTo: dateTo,
      )..add(const DealsListLoadRequested()),
      // The on-page created-at filter only shows when there's no incoming
      // drill-down range to conflict with.
      child: _DealsListView(
        title: title,
        showDateFilter: dateFrom == null && dateTo == null,
      ),
    );
  }
}

class _DealsListView extends StatefulWidget {
  const _DealsListView({this.title, required this.showDateFilter});

  final String? title;
  final bool showDateFilter;

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
  // null = "All" (no filter), same single-select convention as Owner.
  String? _selectedTier;
  _CloseSort _closeSort = _CloseSort.none;
  String? _closeLabel;
  String? _ownerName;
  bool _exporting = false;

  // Stage filter — server-side via the bloc, same as owner. Stages are
  // dynamic/per-company (loaded from GET /deal-stages into `_stages`), so
  // unlike Tier this can't be a fixed checkbox list. Defaults to every stage
  // checked once `_loadStages` resolves ("All", same as the other dropdowns)
  // rather than starting empty -- see `_loadStages` for why that also means
  // dispatching the full id list up front instead of leaving it unset.
  final Set<int> _selectedStageIds = {};

  // On-page date-range filter — server-side via the bloc, same as owner.
  // Only rendered when `widget.showDateFilter` is true (i.e. no drill-down
  // range came in via the constructor). Always filters on `closed_at` (via
  // deal_stage_history, API doc §6.3) rather than `created_at` — there used
  // to be a "Date Type" toggle between the two, but that let a rep pick
  // `created_at` and see a different count than the dashboard's Deals Closed
  // tile for the same range. Hard-coding `closed_at` makes the two agree by
  // construction, with no filter step required to reconcile them.
  DateTime? _dateFrom;
  DateTime? _dateTo;

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
    result.fold((_) {}, (s) {
      setState(() {
        _stages = s;
        _selectedStageIds
          ..clear()
          ..addAll(s.map((e) => e.id));
      });
      // Send the full id list explicitly, rather than leaving stage_id unset,
      // so a `closed_at` date range picked afterwards doesn't fall back to
      // the API's Closed-Won-only default meant for the dashboard drill-down
      // (`deal_service._deal_filters`) — every stage checked here means "no
      // filter", same as the dropdown's own convention below.
      context.read<DealsListBloc>().add(
        DealsListFilterChanged(stageId: _selectedStageIds.toList()),
      );
    });
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
    if (_selectedTier != null) {
      out = out.where((d) => d.tier.toLowerCase() == _selectedTier).toList();
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
            Divider(height: 1, color: AppColors.border),
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

    final tiers = _selectedTier == null ? null : [_selectedTier!];
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
        Text(widget.title ?? 'Deals', style: AppTextStyles.h1),
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
              Text(widget.title ?? 'Deals', style: AppTextStyles.h1),
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
        if (widget.showDateFilter) ...[
          const SizedBox(width: AppSpacing.sm),
          // Always filters by Closed Date (`closed_at`, via
          // deal_stage_history) — see the field comment on `_dateFrom` above
          // for why there's no Created/Closed toggle here anymore.
          OutlinedButton.icon(
            onPressed: () => _pickDateRange(context),
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(
              _dateFrom != null && _dateTo != null
                  ? '${DateFormatter.shortDate(_dateFrom!)} – ${DateFormatter.shortDate(_dateTo!)}'
                  : 'Date Range',
            ),
          ),
          if (_dateFrom != null && _dateTo != null)
            IconButton(
              onPressed: () => _clearDateRange(context),
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Clear date filter',
              visualDensity: VisualDensity.compact,
            ),
        ],
        const SizedBox(width: AppSpacing.md),
        Container(width: 1, height: 24, color: AppColors.border),
        const SizedBox(width: AppSpacing.md),
        _FilterDropdown(
          label: 'Tier',
          icon: Icons.diamond_outlined,
          selected: _selectedTier == null
              ? null
              : '${_selectedTier![0].toUpperCase()}${_selectedTier!.substring(1)}',
          options: [
            'All',
            ..._kTierOrder.map((t) => '${t[0].toUpperCase()}${t.substring(1)}'),
          ],
          onSelected: (v) => setState(
            () => _selectedTier = v == 'All' ? null : v.toLowerCase(),
          ),
        ),
        if (_stages.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.sm),
          _MultiSelectFilterDropdown<DealStageDef>(
            label: 'Stage',
            icon: Icons.flag_outlined,
            options: _stages,
            optionLabel: (s) => s.name,
            selected: _stages
                .where((s) => _selectedStageIds.contains(s.id))
                .toSet(),
            onChanged: _onStageSelectionChanged,
          ),
        ],
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

  void _onStageSelectionChanged(Set<DealStageDef> next) {
    setState(() {
      _selectedStageIds
        ..clear()
        ..addAll(next.map((s) => s.id));
    });
    // Empty (everything unchecked) is treated the same as "all" -- no filter
    // -- the same convention Tier used to follow. Sent as the full id list
    // rather than cleared outright so an active `closed_at` date range
    // doesn't fall back to the API's Closed-Won-only default meant for the
    // dashboard drill-down (`deal_service._deal_filters`).
    final effective = _selectedStageIds.isEmpty
        ? _stages.map((s) => s.id).toList()
        : _selectedStageIds.toList();
    context.read<DealsListBloc>().add(
      DealsListFilterChanged(stageId: effective),
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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showCompactDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialStart: _dateFrom,
      initialEnd: _dateTo,
    );
    if (picked == null || !context.mounted) return;
    setState(() {
      _dateFrom = picked.start;
      _dateTo = picked.end;
    });
    context.read<DealsListBloc>().add(
      DealsListFilterChanged(
        dateFrom: picked.start,
        dateTo: picked.end,
        dateField: 'closed_at',
      ),
    );
  }

  void _clearDateRange(BuildContext context) {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    context.read<DealsListBloc>().add(
      const DealsListFilterChanged(clearDate: true),
    );
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
      _selectedTier = null;
      // Back to "all checked" (no filter), not empty -- matches `_loadStages`.
      _selectedStageIds
        ..clear()
        ..addAll(_stages.map((s) => s.id));
      _closeSort = _CloseSort.none;
      _closeLabel = null;
      _ownerName = null;
      _dateFrom = null;
      _dateTo = null;
    });
    context.read<DealsListBloc>().add(
      DealsListFilterChanged(
        clearOwner: true,
        clearDate: true,
        stageId: _selectedStageIds.toList(),
      ),
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
                    color: AppColors.shadow,
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
            decoration: BoxDecoration(
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
                    Icon(Icons.check, size: 16, color: AppColors.primary),
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

/// Same button chrome as [_FilterDropdown], but the menu stays open across
/// taps so multiple options can be checked in one go (`stage_id` is
/// repeatable on the API — doc §6.3). A `PopupMenuButton`/`showMenu` always
/// pops on an item tap by design; `PopupMenuItem.enabled: false` is the
/// standard workaround — it skips the item's own tap-to-close `InkWell`
/// entirely, leaving the `Checkbox` inside as the only interactive thing.
class _MultiSelectFilterDropdown<T> extends StatelessWidget {
  const _MultiSelectFilterDropdown({
    required this.label,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onChanged,
    this.icon,
  });
  final String label;
  final List<T> options;
  final String Function(T) optionLabel;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Everything checked reads the same as nothing checked -- "All", not a
    // filter -- same convention as every single-select dropdown here.
    final isAllSelected =
        options.isNotEmpty && selected.length == options.length;
    final active = selected.isNotEmpty && !isAllSelected;
    final buttonLabel = selected.isEmpty || isAllSelected
        ? label
        : selected.length == 1
        ? optionLabel(selected.first)
        : '$label (${selected.length})';
    return PopupMenuButton<void>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      itemBuilder: (context) {
        // Captured once per menu open (`itemBuilder` runs a single time),
        // then mutated in place across taps -- `onChanged`'s `selected`
        // param is snapshotted at open time too, so recomputing "current
        // selection" from it on every tap would silently drop everything
        // but the most recent toggle once more than one box is checked in
        // the same open session.
        final localSelected = Set<T>.from(selected);
        return [
          PopupMenuItem<void>(
            enabled: false,
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setMenuState) => ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((option) {
                      final isSelected = localSelected.contains(option);
                      return CheckboxListTile(
                        value: isSelected,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(optionLabel(option)),
                        onChanged: (v) {
                          v == true
                              ? localSelected.add(option)
                              : localSelected.remove(option);
                          setMenuState(() {});
                          onChanged(Set<T>.from(localSelected));
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ];
      },
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
              buttonLabel,
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
