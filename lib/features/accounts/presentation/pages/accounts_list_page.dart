import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/file_download/file_download.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../../app/router/route_paths.dart';
import '../../domain/usecases/export_accounts_usecase.dart';
import '../../../leads/domain/entities/lead_enums.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/account.dart';
import '../bloc/accounts_list_bloc.dart';

class AccountsListPage extends StatelessWidget {
  const AccountsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountsListBloc>()..add(const AccountsListLoadRequested()),
      child: const _AccountsListView(),
    );
  }
}

class _AccountsListView extends StatefulWidget {
  const _AccountsListView();

  @override
  State<_AccountsListView> createState() => _AccountsListViewState();
}

class _AccountsListViewState extends State<_AccountsListView> {
  List<OwnerUser> _users = [];
  int? _ownerId;
  // Selected display labels for the Tier/Industry filters (null = "All"), so
  // the dropdown chrome can reflect the active choice.
  String? _tier;
  String? _industry;
  final Set<String> _selected = {};
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Exports the currently-filtered accounts as an `.xlsx` via
  /// `GET /accounts?to_export=true`. Reads the active filters from the bloc
  /// so the file matches the on-screen list.
  Future<void> _onExport(BuildContext context) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AccountsListBloc>().state;
    setState(() => _exporting = true);

    final search = state is AccountsListLoaded ? state.search : null;
    final industry = state is AccountsListLoaded ? state.industryFilter : null;
    final tier = state is AccountsListLoaded ? state.tierFilter : null;
    final ownerId = state is AccountsListLoaded ? state.ownerFilter : null;

    final result = await sl<ExportAccountsUseCase>()(
      ExportAccountsParams(
        search: search,
        industry: industry,
        tier: tier,
        ownerId: ownerId,
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
        await downloadBytes(bytes, 'accounts.xlsx');
        messenger.showSnackBar(
          const SnackBar(content: Text('Accounts exported.')),
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
              child: BlocBuilder<AccountsListBloc, AccountsListState>(
                builder: (context, state) {
                  if (state is AccountsListLoading) {
                    return const AppLoadingIndicator(message: 'Loading accounts...');
                  }
                  if (state is AccountsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<AccountsListBloc>().add(const AccountsListLoadRequested()),
                    );
                  }
                  if (state is AccountsListLoaded) {
                    if (state.accounts.isEmpty) {
                      return const EmptyState(
                        icon: Icons.business_outlined,
                        title: 'No accounts found',
                        subtitle: 'Adjust your filters or add a new account',
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: _AccountsTable(
                            accounts: state.accounts,
                            selected: _selected,
                            onToggle: (id) => setState(() {
                              _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                            }),
                            onToggleAll: (checked) => setState(() {
                              if (checked) {
                                _selected.addAll(state.accounts.map((a) => a.id));
                              } else {
                                _selected.removeAll(state.accounts.map((a) => a.id));
                              }
                            }),
                          ),
                        ),
                        _PaginationBar(state: state),
                      ],
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
        Text('Accounts', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          'Manage your customer accounts and relationships',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
    final newBtn = ElevatedButton.icon(
      onPressed: () => context.go(RoutePaths.createAccount),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('New Account'),
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _exportButton(context)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: newBtn),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        _exportButton(context),
        const SizedBox(width: AppSpacing.sm),
        newBtn,
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    final bloc = context.read<AccountsListBloc>();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: AppSearchField(
              hintText: 'Search by company name or domain',
              onChanged: (query) => bloc.add(AccountsListSearchChanged(query)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Tier',
            selected: _tier,
            options: ['All', ...leadTierLabels.values],
            onSelected: (v) {
              setState(() => _tier = v == 'All' ? null : v);
              bloc.add(
                AccountsListFilterChanged(
                  tier: v == 'All' ? 'All' : wireValueForLabel(leadTierLabels, v),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _OwnerFilterDropdown(
            users: _users,
            selectedId: _ownerId,
            onSelected: (id) {
              setState(() => _ownerId = id);
              bloc.add(AccountsListFilterChanged(
                ownerId: id ?? AccountsListFilterChanged.clearOwner,
              ));
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Industry',
            selected: _industry,
            options: ['All', ...AppConstants.industries],
            onSelected: (v) {
              setState(() => _industry = v == 'All' ? null : v);
              bloc.add(AccountsListFilterChanged(industry: v));
            },
          ),
        ],
      ),
    );
  }
}

class _AccountsTable extends StatelessWidget {
  const _AccountsTable({
    required this.accounts,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });
  final List<Account> accounts;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<bool> onToggleAll;

  @override
  Widget build(BuildContext context) {
    final allSelected = accounts.isNotEmpty && accounts.every((a) => selected.contains(a.id));
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
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: allSelected,
                    onChanged: (v) => onToggleAll(v ?? false),
                  ),
                ),
                _header('COMPANY NAME', flex: 3),
                _header('DOMAIN', flex: 2),
                _header('INDUSTRY', flex: 2),
                _header('TIER', flex: 2),
                _header('PRIMARY OWNER', flex: 2),
                _header('# CONTACTS', flex: 1),
                _header('# DEALS', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _AccountRow(
                account: accounts[index],
                selected: selected.contains(accounts[index].id),
                onToggle: () => onToggle(accounts[index].id),
              ),
            ),
          ),
        ],
      ),
    );

    // On phones the 7-column table can't fit — let it scroll horizontally
    // at a sensible minimum width instead of squeezing/overflowing cells.
    if (context.isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 900),
          child: SizedBox(
            width: 900,
            child: table,
          ),
        ),
      );
    }
    return table;
  }

  Widget _header(String label, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
  }
}

class _AccountRow extends StatefulWidget {
  const _AccountRow({required this.account, required this.selected, required this.onToggle});
  final Account account;
  final bool selected;
  final VoidCallback onToggle;

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/accounts/${account.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: _isHovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(
                  value: widget.selected,
                  onChanged: (_) => widget.onToggle(),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    InitialsAvatar(name: account.companyName, size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(account.companyName, style: AppTextStyles.tableCellLink, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  account.domain ?? '—',
                  style: AppTextStyles.tableCell.copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(flex: 2, child: Text(account.industry ?? '—', style: AppTextStyles.tableCell)),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: account.tier.trim().isEmpty
                      ? Text('—', style: AppTextStyles.tableCell)
                      : StatusBadge.tier(account.tier),
                ),
              ),
              Expanded(flex: 2, child: OwnerChip(name: account.primaryOwner)),
              Expanded(flex: 1, child: Text('${account.contactCount}', style: AppTextStyles.tableCell)),
              Expanded(flex: 1, child: Text('${account.dealCount}', style: AppTextStyles.tableCell)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.state});
  final AccountsListLoaded state;

  static const _rowsPerPageOptions = [10, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AccountsListBloc>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text('Rows per page:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          DropdownButton<int>(
            value: _rowsPerPageOptions.contains(state.limit) ? state.limit : 25,
            underline: const SizedBox.shrink(),
            items: _rowsPerPageOptions
                .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                .toList(),
            onChanged: (v) {
              if (v != null) bloc.add(AccountsListRowsPerPageChanged(v));
            },
          ),
          const Spacer(),
          Text(
            '${state.pageStart}–${state.pageEnd} of ${state.total}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: state.hasPrev
                ? () => bloc.add(AccountsListPageChanged(state.offset - state.limit))
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: state.hasNext
                ? () => bloc.add(AccountsListPageChanged(state.offset + state.limit))
                : null,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.onSelected,
    this.selected,
  });
  final String label;
  final List<String> options;
  final ValueChanged<String> onSelected;

  /// Selected option label (null when no filter is applied).
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(
                value: option,
                child: _MenuRow(text: option, checked: option == selected),
              ))
          .toList(),
      child: _FilterChrome(label: selected ?? label, active: selected != null),
    );
  }
}

class _OwnerFilterDropdown extends StatelessWidget {
  const _OwnerFilterDropdown({required this.users, required this.selectedId, required this.onSelected});
  final List<OwnerUser> users;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final matches = users.where((u) => u.id == selectedId).toList();
    final active = selectedId != null && matches.isNotEmpty;
    final selectedName = active ? matches.first.displayName : 'Primary Owner';
    // Owner ids are positive; use -1 as the "All" sentinel so the menu item
    // has a non-null value (a null-valued PopupMenuItem never fires
    // onSelected — Flutter treats it as a dismissal).
    return PopupMenuButton<int>(
      onSelected: (v) => onSelected(v == -1 ? null : v),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      itemBuilder: (context) => [
        PopupMenuItem<int>(
          value: -1,
          child: _MenuRow(text: 'All Owners', checked: selectedId == null),
        ),
        ...users.map((u) => PopupMenuItem<int>(
              value: u.id,
              child: _MenuRow(text: u.displayName, checked: u.id == selectedId),
            )),
      ],
      child: _FilterChrome(label: selectedName, active: active),
    );
  }
}

/// A popup-menu row with an optional trailing check for the active option.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.text, required this.checked});
  final String text;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(text)),
        if (checked) const Icon(Icons.check, size: 16, color: AppColors.primary),
      ],
    );
  }
}

class _FilterChrome extends StatelessWidget {
  const _FilterChrome({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryLight : null,
        border: Border.all(color: active ? AppColors.primary : AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
    );
  }
}
