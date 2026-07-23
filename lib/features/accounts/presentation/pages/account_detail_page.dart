import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
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
import '../../../documents/domain/entities/account_document.dart';
import '../../../documents/domain/usecases/get_account_documents_usecase.dart';

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
    _tabController = TabController(length: 6, vsync: this);
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
                            Flexible(child: Text(account.companyName, style: AppTextStyles.h1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: AppSpacing.md),
                            TierBadge(tier: account.tier),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (account.domain != null && account.domain!.isNotEmpty) ...[
                              Text(account.domain!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                              const SizedBox(width: AppSpacing.md),
                            ],
                            const Icon(Icons.person_outline, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(account.primaryOwner, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showEditAccountDialog(context, account),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Account'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('New Contact'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
            Tab(text: 'Contacts${_countSuffix(account.contactCount, state.contacts.length)}'),
            Tab(text: 'Deals${_countSuffix(account.dealCount, state.deals.length)}'),
            const Tab(text: 'Documents'),
            const Tab(text: 'Pre-Sales Checklist'),
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

  /// A " (N)" badge for a tab label. Prefers the loaded list length (what's
  /// actually rendered); falls back to the account's server-reported count
  /// before the list resolves. Empty string when there's nothing to show.
  String _countSuffix(int accountCount, int loadedLength) {
    final n = loadedLength > 0 ? loadedLength : accountCount;
    return n > 0 ? ' ($n)' : '';
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
  const _OverviewTab({required this.state});
  final AccountDetailLoaded state;

  Account get account => state.account;
  List<Contact> get contacts => state.contacts;
  List<Deal> get deals => state.deals;

  String _money(double v) => '₹ ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    // Fields the backend has no model for yet come back null — show a clear
    // "not available" placeholder, never a fake "0".
    const naPlaceholder = 'Not available yet';

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
                      _infoRow('Account Owner', account.primaryOwner),
                      if (account.linkedinUrl != null && account.linkedinUrl!.isNotEmpty)
                        _infoRow('LinkedIn', account.linkedinUrl!),
                      _infoRow('Description', account.description.isEmpty ? 'No description' : account.description),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  title: 'Key Contacts',
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
                                      Row(
                                        children: [
                                          Flexible(child: Text(c.fullName, style: AppTextStyles.labelLarge, overflow: TextOverflow.ellipsis)),
                                          if (c.isPrimary) ...[
                                            const SizedBox(width: AppSpacing.xs),
                                            const _PrimaryBadge(),
                                          ],
                                        ],
                                      ),
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
                  title: 'Account Health',
                  child: Column(
                    children: [
                      _statRow('Open Deal Value', _money(state.openDealValue), Icons.trending_up),
                      const SizedBox(height: AppSpacing.md),
                      _statRow('Total ARR', state.totalArr != null ? _money(state.totalArr!) : naPlaceholder, Icons.savings_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _statRow('Active Deals', '${deals.length}', Icons.handshake_outlined),
                      const SizedBox(height: AppSpacing.md),
                      _statRow('Total Contacts', '${contacts.length}', Icons.people_outline),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SectionCard(
                  title: 'Engagement',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Last Activity', state.lastActivity ?? naPlaceholder),
                      _infoRow('Next Step', state.nextStep ?? naPlaceholder),
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
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
              child: Container(
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
                            onSetPrimary: c.isPrimary ? null : () => _setPrimary(context, c),
                            onEdit: () => _showContactDialog(context, existing: c),
                            onDelete: () => _confirmDelete(context, c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) =>
      Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));

  /// Promote [target] to primary. Per the API a different existing primary
  /// must be unset first (it 409s otherwise), so demote-then-promote.
  Future<void> _setPrimary(BuildContext context, Contact target) async {
    final bloc = context.read<AccountDetailBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final current = contacts.where((c) => c.isPrimary && c.id != target.id);

    if (current.isNotEmpty) {
      final demote = await sl<UpsertAccountContactUseCase>()(
        UpsertAccountContactParams(accountId: _accountId, contactId: current.first.id, isPrimary: false),
      );
      final demoteFailed = demote.isLeft();
      if (demoteFailed) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Could not update the current primary contact.'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
    }

    final result = await sl<UpsertAccountContactUseCase>()(
      UpsertAccountContactParams(accountId: _accountId, contactId: target.id, isPrimary: true),
    );
    result.fold(
      (f) => messenger.showSnackBar(
        SnackBar(content: Text('Could not set primary: ${f.message}'), backgroundColor: AppColors.error),
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
        content: Text('Remove ${c.fullName.isEmpty ? 'this contact' : c.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
        SnackBar(content: Text('Failed to delete: ${f.message}'), backgroundColor: AppColors.error),
      ),
      (_) => bloc.add(AccountDetailLoadRequested(account.id)),
    );
  }

  void _showContactDialog(BuildContext context, {Contact? existing}) {
    final bloc = context.read<AccountDetailBloc>();
    final firstNameController = TextEditingController(text: existing?.firstName ?? '');
    final lastNameController = TextEditingController(text: existing?.lastName ?? '');
    final jobTitleController = TextEditingController(text: existing?.jobTitle ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final altPhoneController = TextEditingController(text: existing?.alternatePhone ?? '');
    final linkedinController = TextEditingController(text: existing?.linkedinUrl ?? '');
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
                          Expanded(child: TextField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name *'))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: TextField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name'))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: jobTitleController, decoration: const InputDecoration(labelText: 'Job Title')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: altPhoneController, decoration: const InputDecoration(labelText: 'Alternate Phone')),
                      const SizedBox(height: AppSpacing.md),
                      TextField(controller: linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL')),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Email or phone is required.', style: AppTextStyles.caption),
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        value: isPrimary,
                        onChanged: (v) => setState(() => isPrimary = v ?? false),
                        title: const Text('Primary contact for this account'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!isEdit && firstNameController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('First name is required.'),
                        backgroundColor: AppColors.error,
                      ));
                      return;
                    }
                    if (emailController.text.trim().isEmpty && phoneController.text.trim().isEmpty) {
                      messenger.showSnackBar(const SnackBar(
                        content: Text('Enter an email or a phone number.'),
                        backgroundColor: AppColors.error,
                      ));
                      return;
                    }

                    String? val(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

                    // If this contact is being made primary and a different
                    // one already is, demote that first to avoid a 409.
                    if (isPrimary) {
                      final other = contacts.where((c) => c.isPrimary && c.id != existing?.id);
                      if (other.isNotEmpty) {
                        await sl<UpsertAccountContactUseCase>()(
                          UpsertAccountContactParams(accountId: _accountId, contactId: other.first.id, isPrimary: false),
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
                        SnackBar(content: Text('Failed to save contact: ${f.message}'), backgroundColor: AppColors.error),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                InitialsAvatar(name: contact.fullName.isEmpty ? (contact.email ?? '?') : contact.fullName, size: 32),
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
          Expanded(flex: 3, child: Text(contact.jobTitle ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Text(contact.email ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(contact.phone ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
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
      child: Text('PRIMARY', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
        _stat('Open Deal Value', '₹ ${state.openDealValue.toStringAsFixed(0)}', highlight: true),
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

/// Account → Documents tab. Backed by a local mock datasource today (no
/// documents API contract yet); filter + pagination + upload are all handled
/// client-side so the flow is reviewable and easy to rewire later.
class _DocumentsTab extends StatefulWidget {
  const _DocumentsTab({required this.accountId});
  final String accountId;

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  static const _pageSize = 3;

  final List<AccountDocument> _all = [];
  final Set<String> _expanded = {};
  String _filter = '';
  int _page = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetAccountDocumentsUseCase>()(widget.accountId);
    if (!mounted) return;
    result.fold(
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

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (!mounted || result == null || result.files.isEmpty) return;
    final f = result.files.first;
    // Mock-only: prepend a local entry so the flow is visible. Real upload
    // (POST /documents/upload) gets wired when the API contract lands.
    setState(() {
      _all.insert(
        0,
        AccountDocument(
          id: 'local_${_all.length}_${f.name}',
          name: f.name,
          sizeBytes: f.size,
          version: 'v1.0',
          uploadedByName: 'You',
          uploadedAt: DateTime.now(),
        ),
      );
      _page = 0;
    });
    messenger.showSnackBar(
      SnackBar(content: Text('“${f.name}” added locally (upload API not wired yet).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AppLoadingIndicator(message: 'Loading documents...');
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);

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
              Expanded(child: Text('Account Documents', style: AppTextStyles.h3)),
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
              ElevatedButton.icon(
                onPressed: _upload,
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: const Text('Upload'),
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
              child: Container(
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
                          _header('NAME', flex: 5),
                          _header('VERSION', flex: 2),
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
                            expanded: _expanded.contains(doc.id),
                            onToggleExpand: doc.hasHistory
                                ? () => setState(() {
                                      _expanded.contains(doc.id)
                                          ? _expanded.remove(doc.id)
                                          : _expanded.add(doc.id);
                                    })
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
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
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: page > 0 ? () => setState(() => _page = page - 1) : null,
                  ),
                  Text('${page + 1} / $totalPages', style: AppTextStyles.bodySmall),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: page < totalPages - 1 ? () => setState(() => _page = page + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(String label, {int flex = 1}) =>
      Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.expanded, required this.onToggleExpand});
  final AccountDocument document;
  final bool expanded;
  /// Null when there's no version history to expand.
  final VoidCallback? onToggleExpand;

  String _size(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  IconData _icon(String ext) {
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xlsx':
      case 'xls':
      case 'csv':
        return Icons.table_chart_outlined;
      case 'docx':
      case 'doc':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      if (onToggleExpand != null)
                        Icon(expanded ? Icons.expand_more : Icons.chevron_right, size: 18, color: AppColors.textMuted)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(_icon(document.extension), size: 22, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(document.name, style: AppTextStyles.tableCellLink, overflow: TextOverflow.ellipsis),
                            Text(_size(document.sizeBytes), style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(document.version, style: AppTextStyles.tableCell.copyWith(color: AppColors.primary))),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      InitialsAvatar(name: document.uploadedByName, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(document.uploadedByName, style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(DateFormat('MMM d, yyyy').format(document.uploadedAt), style: AppTextStyles.tableCell)),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 18),
                        tooltip: 'Download',
                        onPressed: () => messenger.showSnackBar(
                          const SnackBar(content: Text('Download will be wired with the documents API.')),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: 'More',
                        onPressed: () => messenger.showSnackBar(
                          const SnackBar(content: Text('Document actions will be wired with the documents API.')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded && document.hasHistory)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.lg, AppSpacing.md),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Version History', style: AppTextStyles.labelMedium),
                    ],
                  ),
                ),
                ...document.versions.map((v) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          SizedBox(width: 60, child: Text(v.version, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600))),
                          SizedBox(width: 140, child: Text(v.modifiedByName, style: AppTextStyles.bodySmall)),
                          SizedBox(width: 120, child: Text(DateFormat('MMM d, yyyy').format(v.date), style: AppTextStyles.bodySmall)),
                          Expanded(child: Text(v.notes, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
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
                        Text(deal.stageName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
