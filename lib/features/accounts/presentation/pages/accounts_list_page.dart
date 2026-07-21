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
import '../../../leads/domain/entities/lead_enums.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/create_account_usecase.dart';
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
          onPressed: () => _showCreateAccountDialog(context),
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
            options: ['All', ...leadTierLabels.values],
            onSelected: (v) => context.read<AccountsListBloc>().add(
              AccountsListFilterChanged(
                tier: v == 'All' ? 'All' : wireValueForLabel(leadTierLabels, v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAccountDialog(BuildContext context) async {
    final bloc = context.read<AccountsListBloc>();
    final companyController = TextEditingController();
    final domainController = TextEditingController();
    final cityController = TextEditingController();
    final descriptionController = TextEditingController();
    final linkedinController = TextEditingController();
    String tier = leadTierLabels.keys.first;
    String? industry;
    int? ownerId;
    List<OwnerUser> users = [];
    final usersResult = await sl<GetUsersUseCase>()();
    usersResult.fold((_) {}, (u) => users = u);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('New Account'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company *')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: domainController, decoration: const InputDecoration(labelText: 'Domain')),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: tier,
                        decoration: const InputDecoration(labelText: 'Tier'),
                        items: leadTierLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => tier = v!),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String?>(
                        value: industry,
                        decoration: const InputDecoration(labelText: 'Industry'),
                        items: AppConstants.industries.map((i) => DropdownMenuItem<String?>(value: i, child: Text(i))).toList(),
                        onChanged: (v) => setState(() => industry = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: cityController, decoration: const InputDecoration(labelText: 'City')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int?>(
                        value: ownerId,
                        decoration: const InputDecoration(labelText: 'Owner'),
                        items: users.map((u) => DropdownMenuItem<int?>(value: u.id, child: Text(u.displayName))).toList(),
                        onChanged: (v) => setState(() => ownerId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (companyController.text.trim().isEmpty) return;
                    final result = await sl<CreateAccountUseCase>()(
                      AccountUpsertParams(
                        company: companyController.text.trim(),
                        domain: domainController.text.trim().isEmpty ? null : domainController.text.trim(),
                        tier: tier,
                        ownerId: ownerId,
                        industry: industry,
                        city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                        description: descriptionController.text.trim(),
                        linkedinUrl: linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim(),
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create account: ${f.message}'), backgroundColor: AppColors.error),
                      ),
                      (account) {
                        bloc.add(const AccountsListLoadRequested());
                        context.go('/accounts/${account.id}');
                      },
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
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
                _header('CITY', flex: 2),
                _header('TIER', flex: 2),
                _header('OWNER', flex: 2),
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
                          Text(widget.account.domain ?? '—', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(widget.account.industry ?? '—', style: AppTextStyles.tableCell)),
              Expanded(flex: 2, child: Text(widget.account.city ?? '—', style: AppTextStyles.tableCell)),
              Expanded(flex: 2, child: TierBadge(tier: widget.account.tier, showDot: true)),
              Expanded(flex: 2, child: OwnerChip(name: widget.account.primaryOwner)),
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
