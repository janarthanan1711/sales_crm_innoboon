import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/formatters.dart' show DateFormatter;
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/widgets/record_export_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/auth/permissions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../app/di/injector.dart';
import '../../../leads/domain/entities/lead_enums.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/account_activity.dart';
import '../../domain/usecases/create_account_usecase.dart';
import '../../domain/usecases/update_account_usecase.dart';
import '../../domain/usecases/account_activity_usecases.dart';
import '../../domain/usecases/export_accounts_usecase.dart';
import '../bloc/account_detail_bloc.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/domain/usecases/contact_usecases.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';
import '../../../../core/utils/link_launcher.dart';
import '../../../deals/presentation/pages/create_deal_page.dart';
import '../../../documents/domain/entities/account_document.dart';
import '../../../documents/domain/usecases/get_account_documents_usecase.dart';
import '../../../documents/domain/usecases/document_usecases.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<AccountDetailBloc>()..add(AccountDetailLoadRequested(accountId)),
      child: const _AccountDetailView(),
    );
  }
}

class _AccountDetailView extends StatefulWidget {
  const _AccountDetailView();

  @override
  State<_AccountDetailView> createState() => _AccountDetailViewState();
}

class _AccountDetailViewState extends State<_AccountDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {}); // header actions depend on the tab index
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AccountDetailBloc, AccountDetailState>(
        listener: (context, state) {
          if (state is AccountDetailDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted.'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/accounts');
          }
        },
        builder: (context, state) {
          if (state is AccountDetailLoading)
            return const AppLoadingIndicator(message: 'Loading account...');
          if (state is AccountDetailError) {
            return ErrorState(message: state.message, onRetry: () {});
          }
          if (state is AccountDetailLoaded)
            return _buildContent(context, state);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AccountDetailLoaded state) {
    final account = state.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Card ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final identity = Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/accounts'),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      InitialsAvatar(name: account.companyName, size: 48),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    account.companyName,
                                    style: AppTextStyles.h1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                TierBadge(tier: account.tier),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (account.domain != null &&
                                    account.domain!.isNotEmpty) ...[
                                  Flexible(
                                    child: Text(
                                      account.domain!,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                ],
                                const Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    account.primaryOwner,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  // "New Contact" only makes sense from the Overview / Contacts
                  // tabs (index 0 / 1).
                  final showAddContact = _tabController.index <= 1;
                  final actions = [
                    RecordExportButton(
                      fileName: 'account_${account.id}.xlsx',
                      successMessage: 'Account exported.',
                      fetch: () =>
                          sl<ExportAccountDetailUseCase>()(account.id),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showEditAccountDialog(context, account),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Account'),
                    ),
                    if (showAddContact)
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(1),
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('New Contact'),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _openNewDeal(context, account),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Deal'),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'More actions',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'delete') _confirmDeleteAccount(context, account);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              SizedBox(width: AppSpacing.sm),
                              Text('Delete Account', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ];

                  // On phones the three action buttons won't fit beside the
                  // title — stack them into a Wrap underneath instead.
                  if (context.isMobile) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        identity,
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: actions,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: identity),
                      const SizedBox(width: AppSpacing.md),
                      ...[
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          actions[i],
                        ],
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _HeaderStats(state: state),
            ],
          ),
        ),

        // ── Tabs ─────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.labelLarge,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(
              text:
                  'Contacts${_countSuffix(account.contactCount, state.contacts.length)}',
            ),
            Tab(
              text:
                  'Deals${_countSuffix(account.dealCount, state.deals.length)}',
            ),
            const Tab(text: 'Documents'),
            const Tab(text: 'Activity Log'),
          ],
        ),

        // ── Tab Content ──────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(state: state),
              _ContactsTab(account: account, contacts: state.contacts),
              _DealsTab(deals: state.deals),
              _DocumentsTab(accountId: account.id),
              _AccountActivityTab(accountId: account.id),
            ],
          ),
        ),
      ],
    );
  }

  /// A " (N)" badge for a tab label. Prefers the loaded list length (what's
  /// actually rendered); falls back to the account's server-reported count
  /// before the list resolves. Empty string when there's nothing to show.
  String _countSuffix(int accountCount, int loadedLength) {
    final n = loadedLength > 0 ? loadedLength : accountCount;
    return n > 0 ? ' ($n)' : '';
  }

  Future<void> _openNewDeal(BuildContext context, Account account) async {
    final bloc = context.read<AccountDetailBloc>();
    final created = await showDialog<dynamic>(
      context: context,
      builder: (_) => CreateDealDialog(presetAccount: account),
    );
    // The dialog pops non-null on a successful save — refresh so the new deal
    // shows in the Deals tab and count.
    if (created != null) bloc.add(AccountDetailLoadRequested(account.id));
  }

  void _confirmDeleteAccount(BuildContext context, Account account) {
    final bloc = context.read<AccountDetailBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'This will permanently delete "${account.companyName}" and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(AccountDetailDeleteRequested(account.id));
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAccountDialog(
    BuildContext context,
    Account account,
  ) async {
    final bloc = context.read<AccountDetailBloc>();
    final companyController = TextEditingController(text: account.companyName);
    final domainController = TextEditingController(text: account.domain ?? '');
    final cityController = TextEditingController(text: account.city ?? '');
    final descriptionController = TextEditingController(
      text: account.description,
    );
    final linkedinController = TextEditingController(
      text: account.linkedinUrl ?? '',
    );
    String tier = leadTierLabels.containsKey(account.tier)
        ? account.tier
        : leadTierLabels.keys.first;
    String? industry = account.industry;
    int? ownerId = account.ownerId;
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
              title: const Text('Edit Account'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: companyController,
                        decoration: const InputDecoration(labelText: 'Company'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: domainController,
                        decoration: const InputDecoration(labelText: 'Domain'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: tier,
                        decoration: const InputDecoration(labelText: 'Tier'),
                        items: leadTierLabels.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => tier = v!),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String?>(
                        value: industry,
                        decoration: const InputDecoration(
                          labelText: 'Industry',
                        ),
                        items: AppConstants.industries
                            .map(
                              (i) => DropdownMenuItem<String?>(
                                value: i,
                                child: Text(i),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => industry = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn URL',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<int?>(
                        value: ownerId,
                        decoration: const InputDecoration(labelText: 'Owner'),
                        items: users
                            .map(
                              (u) => DropdownMenuItem<int?>(
                                value: u.id,
                                child: Text(u.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => ownerId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final result = await sl<UpdateAccountUseCase>()(
                      UpdateAccountParams(
                        id: account.id,
                        data: AccountUpsertParams(
                          company: companyController.text.trim(),
                          domain: domainController.text.trim().isEmpty
                              ? null
                              : domainController.text.trim(),
                          tier: tier,
                          ownerId: ownerId,
                          industry: industry,
                          city: cityController.text.trim().isEmpty
                              ? null
                              : cityController.text.trim(),
                          description: descriptionController.text.trim(),
                          linkedinUrl: linkedinController.text.trim().isEmpty
                              ? null
                              : linkedinController.text.trim(),
                        ),
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to update account: ${f.message}',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      ),
                      (_) => bloc.add(AccountDetailLoadRequested(account.id)),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.state});
  final AccountDetailLoaded state;

  Account get account => state.account;
  List<Contact> get contacts => state.contacts;
  List<Deal> get deals => state.deals;

  String _money(double v) => '₹ ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    // Left: Account Information + Pre-Sales Checklist (figma).
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Account Information',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _labeled(
                      'Domain',
                      (account.domain != null && account.domain!.isNotEmpty)
                          ? LinkText(
                              text: account.domain!,
                              url: account.domain,
                              maxLines: 1,
                            )
                          : Text('Not set', style: AppTextStyles.bodyMedium),
                    ),
                  ),
                  Expanded(
                    child: _labeled(
                      'Industry',
                      Text(
                        account.industry ?? 'Not set',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _labeled(
                'Description',
                Text(
                  account.description.isEmpty
                      ? 'No description'
                      : account.description,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Pre-Sales Checklist',
          child: deals.isEmpty
              ? Text(
                  'The pre-sales checklist becomes available once this account has a deal.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : SizedBox(
                  height: 420,
                  child: ChecklistView(dealId: deals.first.id),
                ),
        ),
      ],
    );

    // Right: Key Contacts + Active Deals (figma).
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          title: 'Key Contacts',
          child: contacts.isEmpty
              ? Text(
                  'No contacts added yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(children: contacts.take(6).map(_keyContactRow).toList()),
        ),
        const SizedBox(height: AppSpacing.xl),
        SectionCard(
          title: 'Active Deals',
          child: deals.isEmpty
              ? Text(
                  'No active deals',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              : Column(
                  children: deals
                      .map((d) => _activeDealRow(context, d))
                      .toList(),
                ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: AppSpacing.xl),
                right,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: left),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(flex: 3, child: right),
              ],
            ),
    );
  }

  Widget _labeled(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    );
  }

  Widget _keyContactRow(Contact c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          InitialsAvatar(
            name: c.fullName.isEmpty ? (c.email ?? '?') : c.fullName,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.fullName,
                        style: AppTextStyles.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.isPrimary) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const _PrimaryBadge(),
                    ],
                  ],
                ),
                Text(
                  [
                    c.jobTitle,
                    c.email,
                  ].where((s) => s != null && s.isNotEmpty).join(' • '),
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeDealRow(BuildContext context, Deal d) {
    return InkWell(
      onTap: () => context.go('/deals/${d.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    d.name,
                    style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(_money(d.value), style: AppTextStyles.labelMedium),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              d.stageName,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.account, required this.contacts});
  final Account account;
  final List<Contact> contacts;

  int get _accountId => int.tryParse(account.id) ?? 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Associated Contacts', style: AppTextStyles.h3),
                    const SizedBox(height: 2),
                    Text(
                      'Manage the people associated with this account.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showContactDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('Add Contact'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (contacts.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.people_outline,
                title: 'No contacts yet',
                subtitle: 'Add the people you work with at this account.',
              ),
            )
          else
            Expanded(
              child: _mobileScrollTable(
                context,
                Container(
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
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            _headerCell('PRIMARY', flex: 2),
                            _headerCell('NAME', flex: 4),
                            _headerCell('JOB TITLE', flex: 3),
                            _headerCell('EMAIL', flex: 4),
                            _headerCell('PHONE', flex: 3),
                            _headerCell('ACTIONS', flex: 2),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = contacts[index];
                            return _ContactRow(
                              contact: c,
                              onSetPrimary: c.isPrimary
                                  ? null
                                  : () => _setPrimary(context, c),
                              onEdit: () =>
                                  _showContactDialog(context, existing: c),
                              onDelete: () => _confirmDelete(context, c),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label, style: AppTextStyles.tableHeader),
  );

  Widget _mobileScrollTable(
    BuildContext context,
    Widget table, {
    double width = 820,
  }) => accountTableMobileScroll(context, table, width: width);

  /// Promote [target] to primary. Per the API a different existing primary
  /// must be unset first (it 409s otherwise), so demote-then-promote.
  Future<void> _setPrimary(BuildContext context, Contact target) async {
    final bloc = context.read<AccountDetailBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final current = contacts.where((c) => c.isPrimary && c.id != target.id);

    if (current.isNotEmpty) {
      final demote = await sl<UpsertAccountContactUseCase>()(
        UpsertAccountContactParams(
          accountId: _accountId,
          contactId: current.first.id,
          isPrimary: false,
        ),
      );
      final demoteFailed = demote.isLeft();
      if (demoteFailed) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not update the current primary contact.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    final result = await sl<UpsertAccountContactUseCase>()(
      UpsertAccountContactParams(
        accountId: _accountId,
        contactId: target.id,
        isPrimary: true,
      ),
    );
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Could not set primary: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => bloc.add(AccountDetailLoadRequested(account.id)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Contact c) async {
    final bloc = context.read<AccountDetailBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Remove ${c.fullName.isEmpty ? 'this contact' : c.fullName}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await sl<DeleteContactUseCase>()(c.id);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => bloc.add(AccountDetailLoadRequested(account.id)),
    );
  }

  void _showContactDialog(BuildContext context, {Contact? existing}) {
    final bloc = context.read<AccountDetailBloc>();
    final firstNameController = TextEditingController(
      text: existing?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: existing?.lastName ?? '',
    );
    final jobTitleController = TextEditingController(
      text: existing?.jobTitle ?? '',
    );
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final altPhoneController = TextEditingController(
      text: existing?.alternatePhone ?? '',
    );
    final linkedinController = TextEditingController(
      text: existing?.linkedinUrl ?? '',
    );
    bool isPrimary = existing?.isPrimary ?? false;
    final isEdit = existing != null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Contact' : 'Add Contact'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name *',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: altPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Alternate Phone',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn URL',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Email or phone is required.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        value: isPrimary,
                        onChanged: (v) =>
                            setState(() => isPrimary = v ?? false),
                        title: const Text('Primary contact for this account'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!isEdit && firstNameController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('First name is required.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    if (emailController.text.trim().isEmpty &&
                        phoneController.text.trim().isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Enter an email or a phone number.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    String? val(TextEditingController c) =>
                        c.text.trim().isEmpty ? null : c.text.trim();

                    // If this contact is being made primary and a different
                    // one already is, demote that first to avoid a 409.
                    if (isPrimary) {
                      final other = contacts.where(
                        (c) => c.isPrimary && c.id != existing?.id,
                      );
                      if (other.isNotEmpty) {
                        await sl<UpsertAccountContactUseCase>()(
                          UpsertAccountContactParams(
                            accountId: _accountId,
                            contactId: other.first.id,
                            isPrimary: false,
                          ),
                        );
                      }
                    }

                    final result = await sl<UpsertAccountContactUseCase>()(
                      UpsertAccountContactParams(
                        accountId: _accountId,
                        contactId: existing?.id,
                        firstName: val(firstNameController),
                        lastName: val(lastNameController),
                        jobTitle: val(jobTitleController),
                        email: val(emailController),
                        phone: val(phoneController),
                        alternatePhone: val(altPhoneController),
                        linkedinUrl: val(linkedinController),
                        isPrimary: isPrimary,
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to save contact: ${f.message}'),
                          backgroundColor: AppColors.error,
                        ),
                      ),
                      (_) => bloc.add(AccountDetailLoadRequested(account.id)),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onDelete,
  });
  final Contact contact;

  /// Null when this contact is already primary (radio shown selected).
  final VoidCallback? onSetPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Radio<bool>(
              value: true,
              groupValue: contact.isPrimary,
              onChanged: onSetPrimary == null ? null : (_) => onSetPrimary!(),
              toggleable: false,
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                InitialsAvatar(
                  name: contact.fullName.isEmpty
                      ? (contact.email ?? '?')
                      : contact.fullName,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    contact.fullName.isEmpty ? '—' : contact.fullName,
                    style: AppTextStyles.tableCell,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              contact.jobTitle ?? '—',
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              contact.email ?? '—',
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              contact.phone ?? '—',
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  const _PrimaryBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PRIMARY',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The Open Deal Value / Last Activity / Next Step strip under the account
/// header. `last_activity`/`next_step` come back null from the API today, so
/// they show a placeholder rather than a fake value.
class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.state});
  final AccountDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    const na = 'Not available yet';
    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.md,
      children: [
        _stat(
          'Open Deal Value',
          '₹ ${state.openDealValue.toStringAsFixed(0)}',
          highlight: true,
        ),
        _stat('Last Activity', state.lastActivity ?? na),
        _stat('Next Step', state.nextStep ?? na),
      ],
    );
  }

  Widget _stat(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.overline),
        const SizedBox(height: 2),
        Text(
          value,
          style: highlight
              ? AppTextStyles.h3.copyWith(color: AppColors.primary)
              : AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}

/// Turns a relative `/media/...` document path into an absolute URL. Files are
/// served from the server origin (not under the `/api/v1` prefix), so strip
/// that suffix from the Dio base URL before joining.
String _mediaUrl(String fileUrl) {
  if (fileUrl.startsWith('http')) return fileUrl;
  final base = sl<DioClient>().dio.options.baseUrl;
  final origin = base.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
  final path = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
  return '$origin$path';
}

/// Account → Documents tab. Wired to `/accounts/{id}/documents` — list, upload
/// (multipart), view (opens the file's `/media/...` URL) and delete. Filter +
/// pagination stay client-side over the fetched list.
class _DocumentsTab extends StatefulWidget {
  const _DocumentsTab({required this.accountId});
  final String accountId;

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  static const _pageSize = 8;

  final List<AccountDocument> _all = [];
  final Map<int, String> _userNames = {};
  String _filter = '';
  int _page = 0;
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docsResult = await sl<GetAccountDocumentsUseCase>()(widget.accountId);
    final usersResult = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    usersResult.fold((_) {}, (users) {
      _userNames
        ..clear()
        ..addEntries(users.map((u) => MapEntry(u.id, u.displayName)));
    });
    docsResult.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (docs) => setState(() {
        _loading = false;
        _error = null;
        _all
          ..clear()
          ..addAll(docs);
      }),
    );
  }

  List<AccountDocument> get _filtered {
    if (_filter.trim().isEmpty) return _all;
    final q = _filter.toLowerCase();
    return _all.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  String _uploaderName(int id) => _userNames[id] ?? 'User $id';

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    // withData: true so we get bytes for the multipart body (works on web too).
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    final Uint8List? bytes = f.bytes;
    if (bytes == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected file.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _uploading = true);
    final result = await sl<UploadAccountDocumentUseCase>()(
      UploadAccountDocumentParams(
        accountId: widget.accountId,
        bytes: bytes,
        fileName: f.name,
      ),
    );
    if (!mounted) return;
    result.fold(
      (fail) {
        setState(() => _uploading = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${fail.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (doc) {
        messenger.showSnackBar(
          SnackBar(content: Text('“${f.name}” uploaded.')),
        );
        // Reflect immediately from the authoritative upload response. A
        // follow-up GET can race the server's write and return a stale list
        // (which is why the doc only appeared after leaving and re-entering
        // the tab), so insert the returned document directly.
        setState(() {
          _uploading = false;
          _all.removeWhere((d) => d.id == doc.id);
          _all.insert(0, doc);
          _page = 0;
        });
      },
    );
  }

  Future<void> _delete(AccountDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Remove “${doc.name}”? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await sl<DeleteAccountDocumentUseCase>()(
      DeleteAccountDocumentParams(
        accountId: widget.accountId,
        documentId: doc.id,
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Document deleted.')),
        );
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const AppLoadingIndicator(message: 'Loading documents...');
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    final canManage = context.can(Perms.accountsManage);
    final filtered = _filtered;
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    final page = _page.clamp(0, totalPages - 1);
    final start = page * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start.clamp(0, filtered.length), end);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Account Documents', style: AppTextStyles.h3),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  onChanged: (v) => setState(() {
                    _filter = v;
                    _page = 0;
                  }),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'Filter documents...',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (canManage)
                ElevatedButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_outlined, size: 16),
                  label: Text(_uploading ? 'Uploading...' : 'Upload'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (filtered.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.description_outlined,
                title: 'No documents',
                subtitle: 'Upload a document or adjust your filter.',
              ),
            )
          else
            Expanded(
              child: accountTableMobileScroll(
                context,
                Container(
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
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            _header('NAME', flex: 5),
                            _header('UPLOADED BY', flex: 3),
                            _header('DATE', flex: 2),
                            _header('ACTIONS', flex: 2),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: pageItems.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = pageItems[index];
                            return _DocumentRow(
                              document: doc,
                              uploaderName: _uploaderName(doc.uploadedBy),
                              canManage: canManage,
                              onView: () =>
                                  launchWebUrl(_mediaUrl(doc.fileUrl)),
                              onDelete: () => _delete(doc),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    'Showing ${start + 1} to $end of ${filtered.length} documents',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                  ),
                  Text(
                    '${page + 1} / $totalPages',
                    style: AppTextStyles.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: page < totalPages - 1
                        ? () => setState(() => _page = page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label, style: AppTextStyles.tableHeader),
  );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.document,
    required this.uploaderName,
    required this.canManage,
    required this.onView,
    required this.onDelete,
  });
  final AccountDocument document;
  final String uploaderName;
  final bool canManage;
  final VoidCallback onView;
  final VoidCallback onDelete;

  IconData _icon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'png':
      case 'jpg':
      case 'jpeg':
        return Icons.image_outlined;
      case 'docx':
      case 'doc':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// A short, friendly label for the file type shown under the name.
  String _typeLabel() {
    final ext = document.extension;
    if (ext.isNotEmpty) return ext.toUpperCase();
    return document.contentType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(
                  _icon(document.extension),
                  size: 22,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: onView,
                        child: Text(
                          document.name,
                          style: AppTextStyles.tableCellLink,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_typeLabel(), style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(name: uploaderName, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    uploaderName,
                    style: AppTextStyles.tableCell,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('MMM d, yyyy').format(document.createdAt),
              style: AppTextStyles.tableCell,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new, size: 18),
                  tooltip: 'View / Download',
                  onPressed: onView,
                ),
                if (canManage)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    tooltip: 'Delete',
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealsTab extends StatelessWidget {
  const _DealsTab({required this.deals});
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: EmptyState(
          icon: Icons.handshake_outlined,
          title: 'No deals yet',
          subtitle: 'Deals created for this account will show up here.',
        ),
      );
    }
    final totalValue = deals.fold<double>(0, (sum, d) => sum + d.value);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip so the tab answers "how much is on this account?"
          // without the reader adding the rows up.
          Row(
            children: [
              Expanded(
                child: Text(
                  '${deals.length} deal${deals.length == 1 ? '' : 's'}',
                  style: AppTextStyles.labelLarge,
                ),
              ),
              Text(
                'Total: ${CurrencyFormatter.formatINR(totalValue)}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: deals.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _AccountDealCard(deal: deals[index]),
            ),
          ),
        ],
      ),
    );
  }
}

/// A deal row on the Account → Deals tab. Shows value, stage, tier, owner,
/// expected close (with an overdue cue) and linked-contact count — the slim
/// name/stage/value row it replaced didn't carry enough to judge a deal.
class _AccountDealCard extends StatelessWidget {
  const _AccountDealCard({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final close = deal.expectedCloseDate;
    final overdue = close != null && close.isBefore(DateTime.now());

    return InkWell(
      onTap: () => context.go('/deals/${deal.id}'),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    deal.name,
                    style: AppTextStyles.tableCellLink,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  CurrencyFormatter.formatINR(deal.value),
                  style: AppTextStyles.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Wrap so the badge/meta strip reflows instead of overflowing in
            // the narrow tab column.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (deal.stageName.isNotEmpty)
                  StatusBadge.dealStage(deal.stageName),
                if (deal.tier.isNotEmpty) TierBadge(tier: deal.tier),
                _meta(Icons.person_outline, deal.owner),
                if (close != null)
                  _meta(
                    Icons.event_outlined,
                    DateFormatter.displayDate(close),
                    color: overdue ? AppColors.error : null,
                  ),
                if (deal.contacts.isNotEmpty)
                  _meta(
                    Icons.people_outline,
                    '${deal.contacts.length} contact'
                    '${deal.contacts.length == 1 ? '' : 's'}',
                  ),
              ],
            ),
            // Cold deals carry a reason — surface it, it's the whole point of
            // the field.
            if (deal.coldReason != null && deal.coldReason!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.ac_unit,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      deal.coldReason!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color ?? AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: color ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Wraps a fixed-column table so it scrolls horizontally on phones (where the
/// columns can't fit) instead of overflowing. On wider screens the table is
/// returned unchanged.
Widget accountTableMobileScroll(
  BuildContext context,
  Widget table, {
  double width = 820,
}) {
  if (!context.isMobile) return table;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(width: width, child: table),
  );
}

const Map<String, IconData> _accountActivityIcons = {
  'note': Icons.description_outlined,
  'meeting': Icons.event_outlined,
  'call': Icons.call_outlined,
  'comment': Icons.chat_bubble_outline,
  'follow_up': Icons.flag_outlined,
};

/// Node accent colors per activity type (drives the timeline dots).
const Map<String, Color> _accountActivityColors = {
  'note': Color(0xFF8B5CF6),
  'meeting': Color(0xFF3B82F6),
  'call': Color(0xFFF97316),
  'comment': Color(0xFF06B6D4),
  'follow_up': Color(0xFF10B981),
};

/// Account → Activity Log tab. Wired to `/accounts/{id}/activities` — list,
/// log, edit (owner-only server-side) and delete (admin-only server-side).
/// Self-contained so a log/edit/delete refreshes without tearing down the
/// account header/tabs.
class _AccountActivityTab extends StatefulWidget {
  const _AccountActivityTab({required this.accountId});
  final String accountId;

  @override
  State<_AccountActivityTab> createState() => _AccountActivityTabState();
}

class _AccountActivityTabState extends State<_AccountActivityTab> {
  final List<AccountActivity> _activities = [];
  // Selected type filters (starts with all selected → no server filter);
  // date range is applied server-side via date_from / date_to.
  final Set<String> _selectedTypes = {...accountActivityTypeLabels.keys};
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // All (or none) selected → don't send `types` at all (fetch everything);
    // otherwise send just the checked ones as repeatable `types` params.
    final all = _selectedTypes.length == accountActivityTypeLabels.length;
    final types = (all || _selectedTypes.isEmpty)
        ? null
        : _selectedTypes.toList();
    final result = await sl<ListAccountActivitiesUseCase>()(
      ListAccountActivitiesParams(
        accountId: widget.accountId,
        types: types,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (items) => setState(() {
        _loading = false;
        _error = null;
        _activities
          ..clear()
          ..addAll(items);
      }),
    );
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _refresh();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_dateFrom != null && _dateTo != null)
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range == null || !mounted) return;
    setState(() {
      _dateFrom = range.start;
      // date_to is exclusive server-side — add a day so the picked end date
      // is included.
      _dateTo = range.end.add(const Duration(days: 1));
    });
    _refresh();
  }

  void _clearDateRange() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    _refresh();
  }

  void _showLogDialog() {
    String type = accountActivityTypeLabels.keys.first;
    final noteController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            return AlertDialog(
              title: const Text('Log Activity'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Type'),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: accountActivityTypeLabels.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => type = v!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Note'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: noteController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'What happened?',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (noteController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext);
                    _log(type, noteController.text.trim());
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _log(String type, String note) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await sl<LogAccountActivityUseCase>()(
      LogAccountActivityParams(
        accountId: widget.accountId,
        type: type,
        note: note,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to log activity: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => _refresh(),
    );
  }

  void _showEditDialog(AccountActivity activity) {
    final noteController = TextEditingController(text: activity.note);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Activity'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    accountActivityLabel(activity.type),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Note'),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext);
                _update(activity, noteController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _update(AccountActivity activity, String note) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final result = await sl<UpdateAccountActivityUseCase>()(
      UpdateAccountActivityParams(
        accountId: widget.accountId,
        activityId: '${activity.id}',
        note: note,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => _refresh(),
    );
  }

  Future<void> _delete(AccountActivity activity) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this activity?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await sl<DeleteAccountActivityUseCase>()(
      DeleteAccountActivityParams(
        accountId: widget.accountId,
        activityId: '${activity.id}',
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to delete: ${f.message}'),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) => _refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const AppLoadingIndicator(message: 'Loading activity...');
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

    final canManage = context.can(Perms.accountsManage);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Activity Timeline', style: AppTextStyles.h3),
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (canManage)
                ElevatedButton.icon(
                  onPressed: _showLogDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log Activity'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.lg),
          if (_activities.isEmpty)
            Expanded(
              child: EmptyState(
                icon: Icons.history,
                title: _hasActiveFilter
                    ? 'No matching activity'
                    : 'No activity yet',
                subtitle: _hasActiveFilter
                    ? 'Try adjusting the type or date filters above.'
                    : 'Log calls, meetings, and notes to build this account\'s timeline.',
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  final a = _activities[index];
                  return _AccountActivityRow(
                    activity: a,
                    canManage: canManage,
                    isLast: index == _activities.length - 1,
                    onEdit: () => _showEditDialog(a),
                    onDelete: () => _delete(a),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasActiveFilter =>
      _selectedTypes.length != accountActivityTypeLabels.length ||
      _dateFrom != null;

  /// The "Filter Activity" bar — per-type checkboxes plus a date-range button,
  /// all wired to the list API (`types` / `date_from` / `date_to`).
  Widget _buildFilterBar() {
    final hasRange = _dateFrom != null && _dateTo != null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'FILTER ACTIVITY',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          for (final entry in accountActivityTypeLabels.entries)
            _typeCheck(entry.key, entry.value),
          OutlinedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: Text(
              hasRange
                  ? '${DateFormat('MMM d').format(_dateFrom!)} - ${DateFormat('MMM d').format(_dateTo!.subtract(const Duration(days: 1)))}'
                  : 'Date range',
            ),
          ),
          if (_dateFrom != null)
            IconButton(
              tooltip: 'Clear date range',
              onPressed: _clearDateRange,
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _typeCheck(String type, String label) {
    final selected = _selectedTypes.contains(type);
    final color = AppColors.primary;
    return InkWell(
      onTap: () => _toggleType(type),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: selected,
              onChanged: (_) => _toggleType(type),
              activeColor: color,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _accountActivityIcons[type] ?? Icons.circle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _AccountActivityRow extends StatelessWidget {
  const _AccountActivityRow({
    required this.activity,
    required this.canManage,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });
  final AccountActivity activity;
  final bool canManage;
  final bool isLast;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _accountActivityColors[activity.type] ?? AppColors.primary;
    final byline = activity.updatedAt != null && activity.updatedBy != null
        ? 'Edited${activity.updatedByName != null ? ' by ${activity.updatedByName}' : ''}'
        : 'Logged by ${activity.createdByName ?? 'User ${activity.createdBy}'}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline node + connector line.
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  _accountActivityIcons[activity.type] ?? Icons.circle,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : AppColors.border,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                accountActivityLabel(activity.type),
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: color,
                                ),
                              ),
                              Text(
                                '•',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'MMM d, yyyy • h:mm a',
                                ).format(activity.createdAt.toLocal()),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (canManage)
                          SizedBox(
                            height: 24,
                            child: PopupMenuButton<String>(
                              tooltip: 'Actions',
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.more_horiz,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                              onSelected: (v) {
                                if (v == 'edit') onEdit();
                                if (v == 'delete') onDelete();
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: AppSpacing.sm),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(activity.note, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            byline,
                            style: AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
