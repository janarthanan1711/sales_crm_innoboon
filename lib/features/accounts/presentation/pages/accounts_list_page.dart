import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
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

class _AccountsListView extends StatelessWidget {
  const _AccountsListView();

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
                    return _AccountsTable(accounts: state.accounts);
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
              Text('Accounts', style: AppTextStyles.h1),
              const SizedBox(height: 4),
              Text(
                'Manage your customer accounts and relationships',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {}, // context.go(RoutePaths.createAccount) in future
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ New Account'),
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
            width: 280,
            child: AppSearchField(
              hintText: 'Search accounts...',
              onChanged: (query) {
                context.read<AccountsListBloc>().add(AccountsListSearchChanged(query));
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Industry',
            options: ['All', ...AppConstants.industries],
            onSelected: (v) => context.read<AccountsListBloc>().add(AccountsListFilterChanged(industry: v)),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterDropdown(
            label: 'Tier',
            options: ['All', ...AppConstants.tiers],
            onSelected: (v) => context.read<AccountsListBloc>().add(AccountsListFilterChanged(tier: v)),
          ),
        ],
      ),
    );
  }
}

class _AccountsTable extends StatelessWidget {
  const _AccountsTable({required this.accounts});
  final List<Account> accounts;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _header('COMPANY', flex: 3),
                _header('INDUSTRY', flex: 2),
                _header('TIER', flex: 2),
                _header('OWNER', flex: 2),
                _header('CONTACTS', flex: 1),
                _header('ACTIVE DEALS', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) => _AccountRow(account: accounts[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String label, {int flex = 1}) {
    return Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
  }
}

class _AccountRow extends StatefulWidget {
  const _AccountRow({required this.account});
  final Account account;

  @override
  State<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends State<_AccountRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: () => context.go('/accounts/${widget.account.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: _isHovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    InitialsAvatar(name: widget.account.companyName, size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.account.companyName, style: AppTextStyles.tableCellLink, overflow: TextOverflow.ellipsis),
                          Text(widget.account.domain, style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(widget.account.industry, style: AppTextStyles.tableCell)),
              Expanded(flex: 2, child: TierBadge(tier: widget.account.tier, showDot: true)),
              Expanded(flex: 2, child: OwnerChip(name: widget.account.primaryOwner)),
              Expanded(flex: 1, child: Text('${widget.account.contacts.length}', style: AppTextStyles.tableCell)),
              Expanded(flex: 1, child: Text('${widget.account.activeDealsCount}', style: AppTextStyles.tableCell)),
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
