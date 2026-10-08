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
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../domain/entities/deal.dart';
import '../../domain/entities/deal_stage_def.dart';
import '../../domain/usecases/get_deal_stages_usecase.dart';
import '../../domain/usecases/export_deals_usecase.dart';
import '../bloc/deals_list_bloc.dart';
import '../widgets/kanban_board.dart';
import 'create_deal_page.dart';

/// Priority-filter option for deals with no D1–D8 scoring.
const String _kUnscored = 'Unscored';

/// Priority filter options, highest first (server labels, Mode A–D).
const List<String> _kPriorities = ['Very High', 'High', 'Medium', 'Low'];

/// "Due" filter label -> `GET /deals?quick_filter=` key (null = Any Date).
/// Server-side so the rules match the dashboard tiles exactly.
const Map<String, String?> _kDueFilters = {
  'Any Date': null,
  'Due Today': 'due_today',
  'Overdue': 'overdue',
  'Past SLA': 'past_sla',
};

/// Narrowest the deals table gets before it scrolls horizontally.
const double _kTableMinWidth = 2000;

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
    this.quickFilter,
    this.dateField,
    this.dateFrom,
    this.dateTo,
  });

  final String? title;
  final String? stageState;

  /// Dashboard deal-tile drill-down (`in_view`, `very_high`, `overdue`,
  /// `due_today`, `past_sla`) — see `GET /deals?quick_filter=`.
  final String? quickFilter;
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
        quickFilter: quickFilter,
        // Only a dashboard drill-down's range — the on-page Date Range
        // filter was removed.
        dateField: dateField,
        dateFrom: dateFrom,
        dateTo: dateTo,
      )..add(const DealsListLoadRequested()),
      child: _DealsListView(title: title, quickFilter: quickFilter),
    );
  }
}

class _DealsListView extends StatefulWidget {
  const _DealsListView({this.title, this.quickFilter});

  final String? title;

  /// A dashboard drill-down's quick filter, so the Due dropdown can show it.
  final String? quickFilter;

  @override
  State<_DealsListView> createState() => _DealsListViewState();
}

class _DealsListViewState extends State<_DealsListView> {
  bool _isKanbanView = false;
  List<DealStageDef> _stages = [];

  // Client-side filters.
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  _CloseSort _closeSort = _CloseSort.none;
  String? _closeLabel;
  // Client-side over the loaded deals; null = "All".
  // [_kUnscored] = deals with no D1–D8 scoring.
  String? _selectedPriority;
  int? _selectedOwnerId;
  String? _selectedOriginatorKey; // "<type>:<id>", see [_originatorKey]
  // Server-side `quick_filter` label from [_kDueFilters]; null = Any Date.
  String? _selectedDue;
  bool _exporting = false;

  /// Filter panel visibility, toggled by the single Filters icon.
  bool _showFilters = false;

  // Stage filter — server-side via the bloc. Stages are
  // dynamic/per-company (loaded from GET /deal-stages into `_stages`), so
  // unlike Tier this can't be a fixed checkbox list. Defaults to every stage
  // checked once `_loadStages` resolves ("All", same as the other dropdowns)
  // rather than starting empty -- see `_loadStages` for why that also means
  // dispatching the full id list up front instead of leaving it unset.
  final Set<int> _selectedStageIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDue = _kDueFilters.entries
        .where((e) => e.value != null && e.value == widget.quickFilter)
        .map((e) => e.key)
        .firstOrNull;
    _loadStages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  /// deals already loaded from the API.
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
    out = out
        .where(
          (d) =>
              (_selectedPriority == null ||
                  (d.priority ?? _kUnscored) == _selectedPriority) &&
              (_selectedOwnerId == null || d.ownerId == _selectedOwnerId) &&
              (_selectedOriginatorKey == null ||
                  _originatorKey(d) == _selectedOriginatorKey),
        )
        .toList();
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
            const SizedBox(height: AppSpacing.xxl),
            if (!context.isMobile) ...[
              _buildStats(context),
              const SizedBox(height: AppSpacing.xl),
            ],
            _buildFilters(context),
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

    final search = _search.trim().isEmpty ? null : _search.trim();
    final blocState = bloc.state;
    final ownerId =
        _selectedOwnerId ??
        (blocState is DealsListLoaded ? blocState.ownerIdFilter : null);
    final stageId = blocState is DealsListLoaded
        ? blocState.stageIdFilter
        : null;

    final result = await sl<ExportDealsUseCase>()(
      ExportDealsParams(ownerId: ownerId, stageId: stageId, search: search),
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
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)} L';
    return CurrencyFormatter.formatINR(v);
  }

  static bool _isClosed(Deal d) =>
      d.stageIsCold ||
      d.stageName == 'Closed Won' ||
      d.stageName == 'Closed Lost';

  /// KPI strip over the currently-shown deals (same client filters as the
  /// table). "Open pipeline" excludes Closed Won / Closed Lost / Cold.
  Widget _buildStats(BuildContext context) {
    return BlocBuilder<DealsListBloc, DealsListState>(
      builder: (context, state) {
        final deals = state is DealsListLoaded
            ? _applyClientFilters(state.deals)
            : const <Deal>[];
        final open = deals.where((d) => !_isClosed(d)).toList();
        final openValue = open.fold<double>(0, (s, d) => s + d.value);
        final highValue = open.where((d) => d.value >= 2500000).toList();
        final now = DateTime.now();
        final dueSoon = open.where((d) {
          final c = d.expectedCloseDate;
          return c != null && c.difference(now).inDays <= 14;
        }).length;
        final won = deals.where((d) => d.stageName == 'Closed Won').toList();
        final wonValue = won.fold<double>(0, (s, d) => s + d.value);
        final pct = (int part, int whole) =>
            whole == 0 ? '0%' : '${(part * 100 / whole).round()}%';
        return StatCardRow(
          cards: [
            StatCard(
              label: 'Total deals',
              value: '${deals.length}',
              caption: 'In current view',
              dotColor: AppColors.primary,
            ),
            StatCard(
              label: 'Open pipeline',
              value: _compactINR(openValue),
              caption: '${open.length} open deals',
              dotColor: AppColors.success,
            ),
            StatCard(
              label: 'High value',
              value: '${highValue.length}',
              caption: '> ₹25L open',
              captionTrailing: Text(
                pct(highValue.length, open.length),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              dotColor: AppColors.tierGoldText,
            ),
            StatCard(
              label: 'Due soon',
              value: '$dueSoon',
              caption: 'Closing < 14 days',
              dotColor: AppColors.error,
            ),
            StatCard(
              label: 'Closed won',
              value: _compactINR(wonValue),
              caption: '${won.length} deals won',
              dotColor: AppColors.stageWon,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final canManage = context.can(Perms.dealsManage);
    return PageHeader(
      title: widget.title ?? 'Deals',
      subtitle:
          'Pipeline overview, active proposals, and closed opportunities.',
      titleTrailing: _ViewToggle(
        isBoard: _isKanbanView,
        onChanged: (b) => setState(() => _isKanbanView = b),
      ),
      actions: [
        _exportButton(context),
        if (canManage)
          ElevatedButton.icon(
            onPressed: () => _openCreateDealDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Deal'),
          ),
      ],
    );
  }

  /// How many panel filters are narrowing the list — shown on the Filters icon.
  int get _activeFilterCount =>
      [
        _closeLabel,
        _selectedPriority,
        _selectedOwnerId,
        _selectedOriginatorKey,
        _selectedDue,
      ].where((v) => v != null).length +
      (_selectedStageIds.isNotEmpty && _selectedStageIds.length < _stages.length
          ? 1
          : 0);

  Widget _buildFilters(BuildContext context) {
    final bar = Row(
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: 'Search deals, accounts...',
                filled: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Badge(
          isLabelVisible: _activeFilterCount > 0,
          label: Text('$_activeFilterCount'),
          child: IconButton(
            tooltip: _showFilters ? 'Hide filters' : 'Show filters',
            isSelected: _showFilters,
            icon: const Icon(Icons.filter_list),
            selectedIcon: Icon(Icons.filter_list, color: AppColors.primary),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ),
      ],
    );

    final panel = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FilterDropdown(
          label: 'Expected Close',
          icon: Icons.calendar_today_outlined,
          selected: _closeLabel,
          options: const ['Soonest first', 'Latest first', 'Clear'],
          onSelected: _onCloseSelected,
        ),
        ..._buildDealFilters(context),
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar,
          if (_showFilters) ...[
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: panel,
            ),
          ],
        ],
      ),
    );
  }

  /// Priority / Originator / Owner / Due dropdowns. Owner and Originator
  /// options are the people on the loaded deals, so they never list someone
  /// with nothing to show.
  List<Widget> _buildDealFilters(BuildContext context) {
    final state = context.watch<DealsListBloc>().state;
    final deals = state is DealsListLoaded ? state.deals : const <Deal>[];
    final owners = <int, String>{
      for (final d in deals)
        if (d.ownerId != null) d.ownerId!: d.ownerLabel,
    };
    final originators = <String, String>{
      for (final d in deals)
        if (d.originator != null) _originatorKey(d)!: d.originator!.name,
    };
    List<String> sortedNames(Iterable<String> names) =>
        names.toSet().toList()..sort();

    Widget filter(
      String label,
      IconData icon,
      String? selected,
      List<String> options,
      ValueChanged<String?> set,
    ) => Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: _FilterDropdown(
        label: label,
        icon: icon,
        selected: selected,
        options: ['All', ...options],
        onSelected: (v) => setState(() => set(v == 'All' ? null : v)),
      ),
    );

    return [
      filter(
        'Priority',
        Icons.bolt_outlined,
        _selectedPriority,
        [..._kPriorities, _kUnscored],
        (v) => _selectedPriority = v,
      ),
      filter(
        'Originator',
        Icons.person_pin_outlined,
        originators[_selectedOriginatorKey],
        sortedNames(originators.values),
        (v) => _selectedOriginatorKey = v == null
            ? null
            : originators.entries.firstWhere((e) => e.value == v).key,
      ),
      filter(
        'Owner',
        Icons.person_outline,
        owners[_selectedOwnerId],
        sortedNames(owners.values),
        (v) => _selectedOwnerId = v == null
            ? null
            : owners.entries.firstWhere((e) => e.value == v).key,
      ),
      Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: _FilterDropdown(
          label: 'Due',
          icon: Icons.event_outlined,
          selected: _selectedDue,
          options: _kDueFilters.keys.toList(),
          onSelected: _onDueSelected,
        ),
      ),
    ];
  }

  static String? _originatorKey(Deal d) =>
      d.originator == null ? null : '${d.originator!.type}:${d.originator!.id}';

  void _onDueSelected(String label) {
    final key = _kDueFilters[label];
    setState(() => _selectedDue = key == null ? null : label);
    context.read<DealsListBloc>().add(
      key == null
          ? const DealsListFilterChanged(clearQuickFilter: true)
          : DealsListFilterChanged(quickFilter: key),
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
      // Back to "all checked" (no filter), not empty -- matches `_loadStages`.
      _selectedStageIds
        ..clear()
        ..addAll(_stages.map((s) => s.id));
      _closeSort = _CloseSort.none;
      _closeLabel = null;
      _selectedPriority = null;
      _selectedOwnerId = null;
      _selectedOriginatorKey = null;
      _selectedDue = null;
    });
    // No clearDate: the only date range left is a dashboard drill-down's,
    // which is part of what the page is showing, not a user filter.
    context.read<DealsListBloc>().add(
      DealsListFilterChanged(
        stageId: _selectedStageIds.toList(),
        clearQuickFilter: true,
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
    final table = TableCard(
      title: 'Active Pipeline Registry',
      trailing: Text(
        'Showing ${deals.length} deal${deals.length == 1 ? '' : 's'}',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      ),
      header: Row(
        children: [
          _header('DEAL NAME', flex: 3),
          _header('ACCOUNT', flex: 2),
          _header('STAGE', flex: 2),
          _header('PRIORITY', flex: 2),
          _header('VALUE', flex: 2),
          _header('OWNER', flex: 2),
          _header('ORIGINATOR', flex: 2),
          _header('NEXT FOLLOW-UP', flex: 2),
          _header('SCORE', flex: 1),
          _header('MODE', flex: 2),
          _header('PROPOSAL SLA', flex: 2),
          _header('SLA DUE', flex: 2),
        ],
      ),
      body: ListView.separated(
        itemCount: deals.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.borderLight),
        itemBuilder: (context, index) => _DealRow(deal: deals[index]),
      ),
    );

    // Below _kTableMinWidth the table scrolls sideways instead of squeezing
    // its columns. A fixed (tight) width -- NOT just a minWidth -- so the
    // Row-based header/rows get a bounded width for their Expanded children
    // (inside a horizontal scroll view the max width is unbounded).
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kTableMinWidth) return table;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: _kTableMinWidth, child: table),
        );
      },
    );
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
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          color: _isHovered ? AppColors.background : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: TwoLineCell(
                    title: widget.deal.name,
                    subtitle: [
                      'DL-${widget.deal.id}',
                      if (widget.deal.tier.isNotEmpty)
                        '${widget.deal.tier[0].toUpperCase()}${widget.deal.tier.substring(1)} tier',
                    ].join(' · '),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TwoLineCell(
                  leading: InitialsAvatar(
                    name: widget.deal.accountName,
                    size: 32,
                  ),
                  title: widget.deal.accountName,
                  titleStyle: AppTextStyles.tableCell.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge.dealStage(widget.deal.stageLabel),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: widget.deal.priority == null
                      ? Text('—', style: AppTextStyles.tableCell)
                      : StatusBadge.priority(widget.deal.priority!),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  CurrencyFormatter.formatINR(widget.deal.value),
                  style: AppTextStyles.tableCell.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(flex: 2, child: OwnerChip(name: widget.deal.ownerLabel)),
              Expanded(
                flex: 2,
                child: Text(
                  widget.deal.originator?.name ?? '—',
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(flex: 2, child: _followUp(widget.deal)),
              // Scoring is computed server-side; '—' when the deal is unscored.
              Expanded(
                flex: 1,
                child: Text(
                  widget.deal.totalScore?.toString() ?? '—',
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.deal.responseMode ?? '—',
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.deal.proposalSla ?? '—',
                  style: AppTextStyles.tableCell,
                ),
              ),
              Expanded(flex: 2, child: _slaDue(widget.deal)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Proposal SLA due time; red when it has passed and the proposal isn't sent
/// (the same rule as the dashboard's Past SLA tile).
Widget _slaDue(Deal deal) {
  final due = deal.proposalSlaDueAt;
  if (due == null) return Text('—', style: AppTextStyles.tableCell);
  final late =
      deal.proposalStatus != 'proposal_sent' && due.isBefore(DateTime.now());
  return Text(
    DateFormatter.dateTime(due),
    style: AppTextStyles.tableCell.copyWith(
      color: late ? AppColors.error : null,
    ),
  );
}

/// Next follow-up date; red once it's today or past (the dashboard's
/// Due today / Overdue rule).
Widget _followUp(Deal deal) {
  final date = deal.followUpDate;
  if (date == null) return Text('—', style: AppTextStyles.tableCell);
  final now = DateTime.now();
  final due = !date.isAfter(DateTime(now.year, now.month, now.day));
  return Text(
    DateFormatter.displayDate(date),
    style: AppTextStyles.tableCell.copyWith(
      color: due ? AppColors.error : null,
    ),
  );
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
