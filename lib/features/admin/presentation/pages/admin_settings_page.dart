import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../app/di/injector.dart';
import '../../../roles/domain/entities/permission.dart';
import '../../../roles/domain/entities/role.dart';
import '../../../roles/domain/usecases/role_usecases.dart';
import '../../../users/domain/entities/owner_user.dart';
import '../../../users/domain/usecases/get_users_usecase.dart';
import '../../../users/domain/usecases/create_user_usecase.dart';
import '../../../users/domain/usecases/delete_user_usecase.dart';
import '../../../users/domain/usecases/activate_user_usecase.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/usecases/get_audit_log_usecase.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Users / Roles / Audit Log. The "Configuration" tab was dropped —
    // permissions are already managed in the Roles tab.
    _tabController = TabController(length: 3, vsync: this);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Settings', style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  'Manage your organization, team members, and global configurations.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: AppTextStyles.labelLarge,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Roles'),
              Tab(text: 'Audit Log'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_UsersTab(), _RolesTab(), _AuditLogTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Users tab
// ─────────────────────────────────────────────────────────

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<OwnerUser> _users = [];
  List<Role> _roles = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int? _roleFilter;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rolesResult = await sl<ListRolesUseCase>()();
    final usersResult = await sl<GetUsersUseCase>()(
      roleId: _roleFilter,
      status: _statusFilter,
      search: _search.isEmpty ? null : _search,
    );
    if (!mounted) return;
    rolesResult.fold((_) {}, (r) => _roles = r);
    usersResult.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (u) => setState(() {
        _users = u;
        _error = null;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap (not Row) so the filters + action flow onto multiple lines
          // on narrow screens instead of overflowing.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: AppSearchField(
                  hintText: 'Filter by name or email...',
                  onChanged: (v) {
                    _search = v;
                    _load();
                  },
                ),
              ),
              _Dropdown<int?>(
                label: 'All Roles',
                value: _roleFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Roles')),
                  ..._roles.map(
                    (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _roleFilter = v);
                  _load();
                },
              ),
              _Dropdown<String?>(
                label: 'All Status',
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'invited', child: Text('Invited')),
                  DropdownMenuItem(
                    value: 'deactivated',
                    child: Text('Deactivated'),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
              ElevatedButton.icon(
                onPressed: () => _showInviteDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Invite User'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator(message: 'Loading users...')
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _users.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No users found',
                  )
                : _UsersTable(users: _users, onChanged: _load),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    int? roleId = _roles.isNotEmpty ? _roles.first.id : null;
    // Declared out here so they survive the StatefulBuilder's rebuilds.
    var submitting = false;
    String? error;
    // Resolved from the page, which outlives the dialog — the dialog's own
    // context is defunct by the time a post-pop snackbar would use it.
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              final email = emailController.text.trim();
              // These used to `return` silently, so a tap with an empty email
              // looked like a dead button.
              if (email.isEmpty) {
                setState(() => error = 'Email is required.');
                return;
              }
              if (roleId == null) {
                setState(
                  () => error = _roles.isEmpty
                      ? 'No roles available to assign.'
                      : 'Pick a role for this user.',
                );
                return;
              }

              setState(() {
                submitting = true;
                error = null;
              });
              final result = await sl<CreateUserUseCase>()(
                CreateUserParams(
                  email: email,
                  firstName: firstNameController.text.trim(),
                  lastName: lastNameController.text.trim(),
                  roleId: roleId!,
                ),
              );
              if (!dialogContext.mounted) return;
              result.fold(
                // Stay open and report inline. Popping on failure both threw
                // away everything typed and — when a second in-flight request
                // popped again during the exit animation — took the page below
                // with it, tripping go_router's "no pages left" assertion.
                (f) => setState(() {
                  submitting = false;
                  error = f.message;
                }),
                (_) {
                  Navigator.pop(dialogContext);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Invitation sent.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _load();
                },
              );
            }

            return AlertDialog(
              title: const Text('Invite User'),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailController,
                      enabled: !submitting,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: firstNameController,
                      enabled: !submitting,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: lastNameController,
                      enabled: !submitting,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int?>(
                      value: roleId,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: _roles
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (v) => setState(() => roleId = v),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                error!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  // Disabled while in flight: a second tap fired a second POST
                  // and a second pop, which is what crashed the router.
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({required this.users, required this.onChanged});
  final List<OwnerUser> users;
  final VoidCallback onChanged;

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _header('NAME', flex: 3),
                _header('EMAIL', flex: 3),
                _header('ROLE', flex: 2),
                _header('STATUS', flex: 2),
                _header('LAST LOGIN', flex: 2),
                _header('', flex: 1),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _UserRow(user: users[index], onChanged: onChanged),
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

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onChanged});
  final OwnerUser user;
  final VoidCallback onChanged;

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
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(name: user.displayName, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    user.displayName,
                    style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user.email,
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // The chip hugs its label instead of stretching to fill the column:
          // an Expanded Container with no alignment wrapper spanned the full
          // cell width, so every role read as one long tinted bar, and the
          // 2px padding left the text touching its own edges.
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: AppTextStyles.badge.copyWith(color: AppColors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge.userStatus(user.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.lastLoginAt != null
                  ? DateFormatter.relativeTime(user.lastLoginAt!)
                  : 'Never',
              style: AppTextStyles.tableCell,
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) async {
                if (value == 'deactivate') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Deactivate user?'),
                      content: Text(
                        '${user.displayName} will lose access immediately.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text(
                            'Deactivate',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final result = await sl<DeleteUserUseCase>()(user.id);
                  result.fold(
                    (f) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to deactivate: ${f.message}'),
                        backgroundColor: AppColors.error,
                      ),
                    ),
                    (_) => onChanged(),
                  );
                } else if (value == 'activate') {
                  final result = await sl<ActivateUserUseCase>()(user.id);
                  result.fold(
                    (f) => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to activate: ${f.message}'),
                        backgroundColor: AppColors.error,
                      ),
                    ),
                    (_) => onChanged(),
                  );
                }
              },
              itemBuilder: (context) => [
                if (user.status == 'deactivated')
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Activate'),
                  )
                else
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Deactivate'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Roles tab
// ─────────────────────────────────────────────────────────

class _RolesTab extends StatefulWidget {
  const _RolesTab();

  @override
  State<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends State<_RolesTab> {
  List<Role> _roles = [];
  List<Permission> _permissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rolesResult = await sl<ListRolesUseCase>()();
    final permsResult = await sl<ListPermissionsUseCase>()();
    if (!mounted) return;
    permsResult.fold((_) {}, (p) => _permissions = p);
    rolesResult.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (r) => setState(() {
        _roles = r;
        _error = null;
        _loading = false;
      }),
    );
  }

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
              onPressed: () => _showRoleDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Role'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator(message: 'Loading roles...')
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : ListView.separated(
                    itemCount: _roles.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.name,
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  Text(
                                    role.description.isEmpty
                                        ? '${role.permissions.length} permissions'
                                        : role.description,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () =>
                                  _showRoleDialog(context, role: role),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppColors.error,
                              ),
                              onPressed: () => _confirmDelete(context, role),
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

  void _confirmDelete(BuildContext context, Role role) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'This cannot be undone. "${role.name}" will no longer be assignable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result = await sl<DeleteRoleUseCase>()(role.id);
              result.fold(
                (f) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete role: ${f.message}'),
                    backgroundColor: AppColors.error,
                  ),
                ),
                (_) => _load(),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, {Role? role}) {
    final nameController = TextEditingController(text: role?.name ?? '');
    final descriptionController = TextEditingController(
      text: role?.description ?? '',
    );
    final selected = <int>{...?role?.permissions.map((p) => p.id)};
    // Guards against a second tap while the save is in flight — two responses
    // would pop twice, and the second pop takes out the page underneath.
    var saving = false;
    final permissionsByModule = <String, List<Permission>>{};
    for (final p in _permissions) {
      permissionsByModule.putIfAbsent(p.module, () => []).add(p);
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(role == null ? 'New Role' : 'Edit Role'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Role Name',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Permissions', style: AppTextStyles.labelMedium),
                      for (final module in permissionsByModule.keys) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          module.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        ...permissionsByModule[module]!.map(
                          (p) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              p.label,
                              style: AppTextStyles.bodyMedium,
                            ),
                            value: selected.contains(p.id),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                selected.add(p.id);
                              } else {
                                selected.remove(p.id);
                              }
                            }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          setState(() => saving = true);
                          final result = role == null
                              ? await sl<CreateRoleUseCase>()(
                                  CreateRoleParams(
                                    name: nameController.text.trim(),
                                    description: descriptionController.text
                                        .trim(),
                                    permissionIds: selected.toList(),
                                  ),
                                )
                              : await sl<UpdateRoleUseCase>()(
                                  UpdateRoleParams(
                                    id: role.id,
                                    name: nameController.text.trim(),
                                    description: descriptionController.text
                                        .trim(),
                                    permissionIds: selected.toList(),
                                  ),
                                );
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          result.fold(
                            (f) => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to save role: ${f.message}',
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            ),
                            (_) => _load(),
                          );
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Audit Log tab
// ─────────────────────────────────────────────────────────

class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  List<AuditLogEntry> _entries = [];
  List<OwnerUser> _users = [];
  bool _loading = true;
  String? _error;

  String? _tableFilter;
  String? _actionFilter;
  int? _actorFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const int _limit = 20;
  int _offset = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Actors dropdown is populated once; the log list reloads on filter/page.
    final usersResult = await sl<GetUsersUseCase>()();
    if (!mounted) return;
    usersResult.fold((_) {}, (u) => _users = u);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await sl<GetAuditLogUseCase>()(
      GetAuditLogParams(
        tableName: _tableFilter,
        action: _actionFilter,
        actorId: _actorFilter,
        dateFrom: _dateFrom != null ? DateFormatter.apiDate(_dateFrom!) : null,
        dateTo: _dateTo != null ? DateFormatter.apiDate(_dateTo!) : null,
        limit: _limit,
        offset: _offset,
      ),
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _error = f.message;
        _loading = false;
      }),
      (page) => setState(() {
        _entries = page.items;
        _total = page.total;
        _error = null;
        _loading = false;
      }),
    );
  }

  /// Reset to the first page whenever a filter changes, then reload.
  void _applyFilter(VoidCallback change) {
    setState(() {
      change();
      _offset = 0;
    });
    _load();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (picked != null) {
      _applyFilter(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
    }
  }

  bool get _hasDateRange => _dateFrom != null && _dateTo != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Dropdown<String?>(
                label: 'All Tables',
                value: _tableFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Tables'),
                  ),
                  ...kAuditTableNames.map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(_titleCase(t))),
                  ),
                ],
                onChanged: (v) => _applyFilter(() => _tableFilter = v),
              ),
              _Dropdown<String?>(
                label: 'All Actions',
                value: _actionFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Actions'),
                  ),
                  ...kAuditActions.map(
                    (a) =>
                        DropdownMenuItem(value: a, child: Text(_titleCase(a))),
                  ),
                ],
                onChanged: (v) => _applyFilter(() => _actionFilter = v),
              ),
              _Dropdown<int?>(
                label: 'All Actors',
                value: _actorFilter,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Actors'),
                  ),
                  ..._users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.displayName),
                    ),
                  ),
                ],
                onChanged: (v) => _applyFilter(() => _actorFilter = v),
              ),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _hasDateRange
                      ? '${DateFormatter.shortDate(_dateFrom!)} – ${DateFormatter.shortDate(_dateTo!)}'
                      : 'Date Range',
                ),
              ),
              if (_hasDateRange ||
                  _tableFilter != null ||
                  _actionFilter != null ||
                  _actorFilter != null)
                TextButton(
                  onPressed: () => _applyFilter(() {
                    _tableFilter = null;
                    _actionFilter = null;
                    _actorFilter = null;
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                  child: const Text('Clear Filters'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const AppLoadingIndicator(message: 'Loading audit log...')
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _entries.isEmpty
                ? const EmptyState(
                    icon: Icons.history,
                    title: 'No audit entries',
                    subtitle: 'Try adjusting your filters or date range.',
                  )
                : _AuditTable(entries: _entries),
          ),
          if (!_loading && _error == null && _total > 0)
            _AuditPagination(
              offset: _offset,
              limit: _limit,
              total: _total,
              count: _entries.length,
              onPrev: _offset > 0
                  ? () {
                      setState(() => _offset -= _limit);
                      _load();
                    }
                  : null,
              onNext: _offset + _entries.length < _total
                  ? () {
                      setState(() => _offset += _limit);
                      _load();
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.entries});
  final List<AuditLogEntry> entries;

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
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _header('TIMESTAMP', flex: 3),
                _header('ACTOR', flex: 3),
                _header('ACTION', flex: 2),
                _header('TABLE', flex: 2),
                _header('DESCRIPTION', flex: 6),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _AuditRow(entry: entries[index]),
            ),
          ),
        ],
      ),
    );

    // The 5-column table needs room; on phones let it scroll horizontally.
    final isMobile = MediaQuery.sizeOf(context).width < 800;
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 900, child: table),
      );
    }
    return table;
  }

  Widget _header(String label, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(label, style: AppTextStyles.tableHeader),
  );
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});
  final AuditLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              DateFormatter.dateTime(entry.createdAt),
              style: AppTextStyles.tableCell,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                InitialsAvatar(name: entry.actorName, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    entry.actorName,
                    style: AppTextStyles.tableCell,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _ActionBadge(action: entry.action)),
          Expanded(
            flex: 2,
            child: Text(
              _titleCase(entry.tableName),
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(entry.description, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final String action;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (action) {
      case 'created':
        color = AppColors.success;
        break;
      case 'updated':
        color = AppColors.primary;
        break;
      case 'deleted':
      case 'deactivated':
        color = AppColors.error;
        break;
      case 'login':
      case 'logout':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          action.toUpperCase(),
          style: AppTextStyles.badge.copyWith(color: color),
        ),
      ),
    );
  }
}

class _AuditPagination extends StatelessWidget {
  const _AuditPagination({
    required this.offset,
    required this.limit,
    required this.total,
    required this.count,
    required this.onPrev,
    required this.onNext,
  });
  final int offset;
  final int limit;
  final int total;
  final int count;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : offset + 1;
    final end = offset + count;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          Text(
            'Showing $start–$end of $total',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: onPrev,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: (v) {
            if (v != null || items.any((i) => i.value == null)) {
              onChanged(v as T);
            }
          },
          hint: Text(label, style: AppTextStyles.labelMedium),
        ),
      ),
    );
  }
}
