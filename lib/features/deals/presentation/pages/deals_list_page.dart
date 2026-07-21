import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/deal.dart';
import '../bloc/deals_list_bloc.dart';
import '../widgets/kanban_board.dart';
import 'create_deal_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final result = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    result.fold((_) {}, (u) => setState(() => _users = u));
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
            const SizedBox(height: AppSpacing.xl),
            _buildFilters(context),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocConsumer<DealsListBloc, DealsListState>(
                listener: (context, state) {
                  if (state is DealsListLoaded && state.actionError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.actionError!), backgroundColor: AppColors.error),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is DealsListLoading) {
                    return const AppLoadingIndicator(message: 'Loading deals...');
                  }
                  if (state is DealsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<DealsListBloc>().add(const DealsListLoadRequested()),
                    );
                  }
                  if (state is DealsListLoaded) {
                    if (state.deals.isEmpty) {
                      return const EmptyState(
                        icon: Icons.monetization_on_outlined,
                        title: 'No deals found',
                        subtitle: 'Adjust your filters or add a new deal',
                      );
                    }
                    return _isKanbanView
                        ? KanbanBoard(deals: state.deals)
                        : _DealsTable(deals: state.deals);
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
    showDialog(context: context, builder: (_) => const CreateDealDialog()).then((result) {
      if (result != null) bloc.add(const DealsListLoadRequested());
    });
  }

  Widget _buildHeader(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deals Pipeline', style: AppTextStyles.h1),
          const SizedBox(height: 4),
          Text(
            'Track and manage your active opportunities',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.view_kanban, color: _isKanbanView ? AppColors.primary : AppColors.textMuted),
                      onPressed: () => setState(() => _isKanbanView = true),
                      tooltip: 'Board View',
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    IconButton(
                      icon: Icon(Icons.table_rows_outlined, color: !_isKanbanView ? AppColors.primary : AppColors.textMuted),
                      onPressed: () => setState(() => _isKanbanView = false),
                      tooltip: 'Table View',
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openCreateDealDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Deal'),
              ),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deals Pipeline', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                'Track and manage your active opportunities',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.view_kanban, color: _isKanbanView ? AppColors.primary : AppColors.textMuted),
                onPressed: () => setState(() => _isKanbanView = true),
                tooltip: 'Board View',
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              IconButton(
                icon: Icon(Icons.table_rows_outlined, color: !_isKanbanView ? AppColors.primary : AppColors.textMuted),
                onPressed: () => setState(() => _isKanbanView = false),
                tooltip: 'Table View',
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const CreateDealDialog(),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Deal'),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterDropdown(
            label: 'Owner',
            options: ['All', ..._users.map((u) => u.displayName)],
            onSelected: (v) {
              final bloc = context.read<DealsListBloc>();
              if (v == 'All') {
                bloc.add(const DealsListFilterChanged(clearOwner: true));
                return;
              }
              final match = _users.where((u) => u.displayName == v);
              if (match.isNotEmpty) {
                bloc.add(DealsListFilterChanged(ownerId: match.first.id));
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Stage',
            options: ['All', ...DealStage.values.map((s) => s.name)],
            onSelected: (v) {
              final bloc = context.read<DealsListBloc>();
              if (v == 'All') {
                bloc.add(const DealsListFilterChanged(clearStage: true));
                return;
              }
              final stage = DealStage.values.where((s) => s.name == v);
              if (stage.isNotEmpty) {
                bloc.add(DealsListFilterChanged(stage: stage.first));
              }
            },
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: table,
        ),
      );
    }
    return table;
  }

  Widget _header(String label, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: _isHovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(widget.deal.name, style: AppTextStyles.tableCellLink)),
              Expanded(flex: 2, child: Text(widget.deal.accountName, style: AppTextStyles.tableCell)),
              Expanded(
                flex: 2, 
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.deal.stage.name, style: AppTextStyles.caption),
                  ),
                ),
              ),
              Expanded(flex: 1, child: Text(CurrencyFormatter.formatINR(widget.deal.value), style: AppTextStyles.tableCell)),
              Expanded(flex: 2, child: OwnerChip(name: widget.deal.owner)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, required this.options, required this.onSelected});
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      itemBuilder: (context) => options.map((option) => PopupMenuItem(value: option, child: Text(option))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
