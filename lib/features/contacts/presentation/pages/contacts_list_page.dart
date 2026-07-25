import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/get_accounts_usecase.dart';
import '../../domain/entities/contact.dart';
import '../bloc/contacts_list_bloc.dart';
import '../widgets/contact_form_dialog.dart';

const List<String> _kTiers = ['diamond', 'gold', 'silver', 'bronze'];

class ContactsListPage extends StatelessWidget {
  const ContactsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ContactsListBloc>()..add(const ContactsListLoadRequested()),
      child: const _ContactsListView(),
    );
  }
}

class _ContactsListView extends StatefulWidget {
  const _ContactsListView();

  @override
  State<_ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<_ContactsListView> {
  final _searchController = TextEditingController();
  final Set<int> _selected = {};

  List<OwnerUser> _owners = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final usersResult = await sl<GetUsersUseCase>()();
    final accountsResult = await sl<GetAccountsUseCase>()(const GetAccountsParams(limit: 1000));
    if (!mounted) return;
    setState(() {
      usersResult.fold((_) {}, (u) => _owners = u);
      accountsResult.fold((_) {}, (page) => _accounts = page.items);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(_selected.clear);
    context.read<ContactsListBloc>().add(const ContactsListCleared());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(context.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            _buildFilters(context),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: BlocConsumer<ContactsListBloc, ContactsListState>(
                listener: (context, state) {
                  if (state is ContactsListLoaded && state.actionError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.actionError!), backgroundColor: AppColors.error),
                    );
                  }
                  if (state is ContactsListLoaded) {
                    final ids = state.contacts.map((c) => c.id).toSet();
                    _selected.removeWhere((id) => !ids.contains(id));
                  }
                },
                builder: (context, state) {
                  if (state is ContactsListLoading || state is ContactsListInitial) {
                    return const AppLoadingIndicator(message: 'Loading contacts...');
                  }
                  if (state is ContactsListError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<ContactsListBloc>().add(const ContactsListLoadRequested()),
                    );
                  }
                  if (state is ContactsListLoaded) {
                    if (state.contacts.isEmpty) {
                      return const EmptyState(
                        icon: Icons.contacts_outlined,
                        title: 'No contacts found',
                        subtitle: 'Adjust your filters or add a new contact',
                      );
                    }
                    return Column(
                      children: [
                        if (_selected.isNotEmpty) _buildBulkBar(context),
                        Expanded(child: _buildTable(context, state)),
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

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contacts', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        Text(
          'People across your accounts',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
    final importBtn = OutlinedButton.icon(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact import is coming soon.')),
      ),
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Import Contacts'),
    );
    final newBtn = ElevatedButton.icon(
      onPressed: () => _openContactDialog(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('New Contact'),
    );

    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: AppSpacing.md),
          Row(children: [Expanded(child: importBtn), const SizedBox(width: AppSpacing.sm), Expanded(child: newBtn)]),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        importBtn,
        const SizedBox(width: AppSpacing.sm),
        newBtn,
      ],
    );
  }

  // ── Filters ────────────────────────────────────────────
  Widget _buildFilters(BuildContext context) {
    final bloc = context.read<ContactsListBloc>();
    final loaded = context.watch<ContactsListBloc>().state;
    final primaryOnly = loaded is ContactsListLoaded && loaded.primaryOnly;
    final ownerFilter = loaded is ContactsListLoaded ? loaded.ownerFilter : null;
    final accountFilter = loaded is ContactsListLoaded ? loaded.accountFilter : null;
    final tierFilter = loaded is ContactsListLoaded ? loaded.tierFilter : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: context.isMobile ? 200 : 280,
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search by name, email...',
              onChanged: (q) => bloc.add(ContactsListSearchChanged(q)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MenuFilter<int?>(
            label: 'Owner',
            selected: ownerFilter,
            options: [
              const MapEntry<int?, String>(null, 'All Owners'),
              ..._owners.map((o) => MapEntry<int?, String>(o.id, o.displayName)),
            ],
            onSelected: (v) => bloc.add(ContactsListFilterChanged(
              ownerId: v ?? ContactsListFilterChanged.clearOwner,
            )),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MenuFilter<int?>(
            label: 'Account',
            selected: accountFilter,
            options: [
              const MapEntry<int?, String>(null, 'All Accounts'),
              ..._accounts.map((a) => MapEntry<int?, String>(int.tryParse(a.id), a.companyName)),
            ],
            onSelected: (v) => bloc.add(ContactsListFilterChanged(
              accountId: v ?? ContactsListFilterChanged.clearAccount,
            )),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MenuFilter<String?>(
            label: 'Tier',
            selected: tierFilter,
            options: [
              const MapEntry<String?, String>(null, 'All Tiers'),
              ..._kTiers.map((t) => MapEntry<String?, String>(t, _titleCase(t))),
            ],
            onSelected: (v) => bloc.add(ContactsListFilterChanged(tier: v ?? 'all')),
          ),
          const SizedBox(width: AppSpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: primaryOnly,
                onChanged: (v) => bloc.add(ContactsListFilterChanged(isPrimary: v)),
              ),
              Text('Primary Only', style: AppTextStyles.labelMedium),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: _clearFilters, child: const Text('Clear Filters')),
        ],
      ),
    );
  }

  // ── Bulk action bar ────────────────────────────────────
  Widget _buildBulkBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('${_selected.length} contacts selected', style: AppTextStyles.labelMedium),
            const SizedBox(width: AppSpacing.lg),
            TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reassigning owners is coming soon.')),
              ),
              icon: const Icon(Icons.person_pin_outlined, size: 16),
              label: const Text('Reassign Owner'),
            ),
            TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export is coming soon.')),
              ),
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export Selected'),
            ),
            TextButton.icon(
              onPressed: () => _confirmBulkDelete(context),
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              label: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
            IconButton(
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────
  Widget _buildTable(BuildContext context, ContactsListLoaded state) {
    final allSelected = state.contacts.isNotEmpty && state.contacts.every((c) => _selected.contains(c.id));
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
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Checkbox(
                    value: allSelected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _selected.addAll(state.contacts.map((c) => c.id));
                      } else {
                        _selected.clear();
                      }
                    }),
                  ),
                ),
                _h('CONTACT NAME', flex: 4),
                _h('JOB TITLE', flex: 3),
                _h('ASSOCIATED ACCOUNT', flex: 3),
                _h('EMAIL', flex: 4),
                _h('PHONE', flex: 3),
                SizedBox(width: 96, child: Text('ACTIONS', style: AppTextStyles.tableHeader)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: state.contacts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = state.contacts[index];
                return _ContactRow(
                  contact: c,
                  selected: _selected.contains(c.id),
                  onToggle: () => setState(() {
                    _selected.contains(c.id) ? _selected.remove(c.id) : _selected.add(c.id);
                  }),
                  onView: () => context.go('/contacts/${c.id}'),
                  onEdit: () => _openContactDialog(context, existing: c),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (context.isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 980, child: table),
      );
    }
    return table;
  }

  Widget _h(String label, {int flex = 1}) =>
      Expanded(flex: flex, child: Text(label, style: AppTextStyles.tableHeader));

  // ── Actions ────────────────────────────────────────────
  Future<void> _openContactDialog(BuildContext context, {Contact? existing}) async {
    final bloc = context.read<ContactsListBloc>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ContactFormDialog(accounts: _accounts, existing: existing),
    );
    if (saved == true) bloc.add(const ContactsListLoadRequested());
  }

  void _confirmBulkDelete(BuildContext context) {
    final bloc = context.read<ContactsListBloc>();
    final ids = _selected.toList();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${ids.length} contact(s)?'),
        content: const Text('This removes the contacts entirely. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              bloc.add(ContactsListDeleteRequested(ids));
              setState(_selected.clear);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ─── Row ────────────────────────────────────────────────
class _ContactRow extends StatefulWidget {
  const _ContactRow({
    required this.contact,
    required this.selected,
    required this.onToggle,
    required this.onView,
    required this.onEdit,
  });
  final Contact contact;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  State<_ContactRow> createState() => _ContactRowState();
}

class _ContactRowState extends State<_ContactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onView,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          color: _hovered ? AppColors.navHover : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Checkbox(value: widget.selected, onChanged: (_) => widget.onToggle()),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    InitialsAvatar(name: c.fullName.isEmpty ? c.firstName : c.fullName, size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(c.fullName, style: AppTextStyles.tableCellLink, overflow: TextOverflow.ellipsis),
                    ),
                    if (c.isPrimary) ...[
                      const SizedBox(width: 6),
                      const _PrimaryBadge(),
                    ],
                  ],
                ),
              ),
              Expanded(flex: 3, child: Text(c.jobTitle ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
              Expanded(
                flex: 3,
                child: Text(
                  c.accountName ?? '—',
                  style: AppTextStyles.tableCell.copyWith(color: c.accountName != null ? AppColors.primary : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(flex: 4, child: Text(c.email ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
              Expanded(flex: 3, child: Text(c.phone ?? '—', style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis)),
              SizedBox(
                width: 96,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      tooltip: 'View',
                      onPressed: widget.onView,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      onPressed: widget.onEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 10, color: AppColors.success),
          const SizedBox(width: 2),
          Text('PRIMARY', style: AppTextStyles.overline.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

// ─── Filter menu ────────────────────────────────────────
class _MenuFilter<T> extends StatelessWidget {
  const _MenuFilter({
    required this.label,
    required this.options,
    required this.onSelected,
    this.selected,
  });
  final String label;
  final List<MapEntry<T, String>> options;
  final ValueChanged<T> onSelected;

  /// Currently-applied filter key. When it matches a non-default option the
  /// chrome shows that option's label instead of the static [label].
  final T? selected;

  @override
  Widget build(BuildContext context) {
    // The first option is the "All …" default (key is null/'all'); only treat
    // a match against a later option as an active selection.
    String? selectedLabel;
    for (var i = 0; i < options.length; i++) {
      if (options[i].key == selected && i != 0) {
        selectedLabel = options[i].value;
        break;
      }
    }
    final active = selectedLabel != null;
    // Use the option index as the menu value (never null) — a PopupMenuItem
    // with a null value never fires onSelected (Flutter treats it as a
    // dismissal), which would make the "All …" option unclickable.
    return PopupMenuButton<int>(
      onSelected: (i) => onSelected(options[i].key),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
      itemBuilder: (context) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Expanded(child: Text(options[i].value)),
                if (options[i].key == selected)
                  const Icon(Icons.check, size: 16, color: AppColors.primary),
              ],
            ),
          ),
      ],
      child: Container(
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
              selectedLabel ?? label,
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

// ─── Pagination ─────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.state});
  final ContactsListLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ContactsListBloc>();
    final start = state.total == 0 ? 0 : state.offset + 1;
    final end = (state.offset + state.contacts.length);
    final canPrev = state.offset > 0;
    final canNext = end < state.total;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Showing $start–$end of ${state.total}', style: AppTextStyles.bodySmall),
            const SizedBox(width: AppSpacing.lg),
            Text('Rows per page:', style: AppTextStyles.bodySmall),
            const SizedBox(width: AppSpacing.sm),
            DropdownButton<int>(
              value: state.limit,
              underline: const SizedBox.shrink(),
              items: const [10, 20, 50]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (n) {
                if (n != null) bloc.add(ContactsListRowsPerPageChanged(n));
              },
            ),
            const SizedBox(width: AppSpacing.lg),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: canPrev ? () => bloc.add(ContactsListPageChanged(state.offset - state.limit)) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: canNext ? () => bloc.add(ContactsListPageChanged(state.offset + state.limit)) : null,
            ),
          ],
        ),
      ),
    );
  }
}
