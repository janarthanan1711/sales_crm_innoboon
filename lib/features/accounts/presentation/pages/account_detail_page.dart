import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../app/di/injector.dart';
import '../../../leads/domain/entities/lead_enums.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/create_account_usecase.dart';
import '../../domain/usecases/update_account_usecase.dart';
import '../bloc/account_detail_bloc.dart';
import '../../../contacts/domain/entities/contact.dart';
import '../../../contacts/domain/usecases/contact_usecases.dart';
import '../../../deals/domain/entities/deal.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../../features/checklist/presentation/widgets/checklist_view.dart';
import '../../../../features/activity/presentation/widgets/activity_timeline_view.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountDetailBloc>()..add(AccountDetailLoadRequested(accountId)),
      child: const _AccountDetailView(),
    );
  }
}

class _AccountDetailView extends StatefulWidget {
  const _AccountDetailView();

  @override
  State<_AccountDetailView> createState() => _AccountDetailViewState();
}

class _AccountDetailViewState extends State<_AccountDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      body: BlocBuilder<AccountDetailBloc, AccountDetailState>(
        builder: (context, state) {
          if (state is AccountDetailLoading) return const AppLoadingIndicator(message: 'Loading account...');
          if (state is AccountDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () {},
            );
          }
          if (state is AccountDetailLoaded) return _buildContent(context, state);
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
              Row(
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
                            Text(account.companyName, style: AppTextStyles.h1),
                            const SizedBox(width: AppSpacing.md),
                            TierBadge(tier: account.tier),
                          ],
                        ),
                        Text(account.domain ?? 'No domain set', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditAccountDialog(context, account),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Account'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deal creation from an account is coming soon.')),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Deal'),
                  ),
                ],
              ),
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
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Contacts'),
            Tab(text: 'Deals'),
            Tab(text: 'Pre-Sales Checklist'),
            Tab(text: 'Activity Log'),
          ],
        ),

        // ── Tab Content ──────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(account: account, contacts: state.contacts, deals: state.deals),
              _ContactsTab(account: account, contacts: state.contacts),
              _DealsTab(deals: state.deals),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: state.deals.isEmpty
                    ? const EmptyState(
                        icon: Icons.checklist_outlined,
                        title: 'No deal yet',
                        subtitle: 'The pre-sales checklist becomes available once this account has a deal.',
                      )
                    : ChecklistView(dealId: state.deals.first.id),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ActivityTimelineView(entityType: 'Account', entityId: account.id),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showEditAccountDialog(BuildContext context, Account account) async {
    final bloc = context.read<AccountDetailBloc>();
    final companyController = TextEditingController(text: account.companyName);
    final domainController = TextEditingController(text: account.domain ?? '');
    final cityController = TextEditingController(text: account.city ?? '');
    final descriptionController = TextEditingController(text: account.description);
    final linkedinController = TextEditingController(text: account.linkedinUrl ?? '');
    String tier = leadTierLabels.containsKey(account.tier) ? account.tier : leadTierLabels.keys.first;
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
                      TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company')),
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
                    final result = await sl<UpdateAccountUseCase>()(
                      UpdateAccountParams(
                        id: account.id,
                        data: AccountUpsertParams(
                          company: companyController.text.trim(),
                          domain: domainController.text.trim().isEmpty ? null : domainController.text.trim(),
                          tier: tier,
                          ownerId: ownerId,
                          industry: industry,
                          city: cityController.text.trim().isEmpty ? null : cityController.text.trim(),
                          description: descriptionController.text.trim(),
                          linkedinUrl: linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim(),
                        ),
                      ),
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    result.fold(
                      (f) => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update account: ${f.message}'), backgroundColor: AppColors.error),
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
  const _OverviewTab({required this.account, required this.contacts, required this.deals});
  final Account account;
  final List<Contact> contacts;
  final List<Deal> deals;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column (Main info)
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Account Information',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Industry', account.industry ?? 'Not set'),
                      _infoRow('City', account.city ?? 'Not set'),
                      _infoRow('Primary Owner', account.primaryOwner),
                      _infoRow('Description', account.description.isEmpty ? 'No description' : account.description),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  title: 'Primary Contacts',
                  child: contacts.isEmpty
                      ? const Text('No contacts added yet')
                      : Column(
                          children: contacts.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              children: [
                                InitialsAvatar(name: c.fullName.isEmpty ? (c.email ?? '?') : c.fullName, size: 36),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.fullName, style: AppTextStyles.labelLarge),
                                      Text(
                                        [c.jobTitle, c.email].where((s) => s != null && s.isNotEmpty).join(' • '),
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xxl),

          // Right column (Side panels)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  title: 'Quick Stats',
                  child: Column(
                    children: [
                      _statRow('Active Deals', '${deals.length}', Icons.handshake_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _statRow('Total Contacts', '${contacts.length}', Icons.people_outline),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Text(value, style: AppTextStyles.h3),
      ],
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.account, required this.contacts});
  final Account account;
  final List<Contact> contacts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _showAddContactDialog(context),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Contact'),
            ),
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
              child: ListView.separated(
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final c = contacts[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        InitialsAvatar(name: c.fullName.isEmpty ? (c.email ?? '?') : c.fullName, size: 36),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.fullName, style: AppTextStyles.labelLarge),
                              Text(
                                [c.jobTitle, c.email, c.phone].where((s) => s != null && s.isNotEmpty).join(' • '),
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    final bloc = context.read<AccountDetailBloc>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final jobTitleController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Contact'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: jobTitleController, decoration: const InputDecoration(labelText: 'Job Title')),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: AppSpacing.md),
                  TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (firstNameController.text.trim().isEmpty) return;
                final result = await sl<CreateContactUseCase>()(
                  CreateContactParams(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim().isEmpty ? null : lastNameController.text.trim(),
                    email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                    jobTitle: jobTitleController.text.trim().isEmpty ? null : jobTitleController.text.trim(),
                    accountId: int.parse(account.id),
                  ),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                result.fold(
                  (f) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add contact: ${f.message}'), backgroundColor: AppColors.error),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: ListView.separated(
        itemCount: deals.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final deal = deals[index];
          return InkWell(
            onTap: () => context.go('/deals/${deal.id}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deal.name, style: AppTextStyles.tableCellLink),
                        Text(deal.stage.name, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('${deal.currency} ${deal.value.toStringAsFixed(0)}', style: AppTextStyles.labelLarge),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
